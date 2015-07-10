require 'pp'
require 'read_code_java'
require 'file_traverse'
require 'utils/nested_pattern'
require 'yaml'


class ClassRelation
  PACKAGE_HEAD  = /^com\.worksap\.company\.(.+)$/

public
  def initialize
    @file_traverse = FileTraverse.new(exclusive: :test, ext: :java)
#    @file_traverse = FileTraverse.new(ext: :java)
    _init_info_extract
  end

  def extract(dn, fn_out)
    out_data = _extract(dn)
    unless fn_out then _print(out_data, STDOUT)
    else File.open(fn_out, 'w') { |f| _print(out_data, f) }
    end
  end


private
  def _init_info_extract
    _short_package = ->(pkg) { (m = pkg.match(PACKAGE_HEAD)) ? m[1] : nil }
    @read_code = ReadCodeJava.new(terminator: %w(; { }))

    pattern = /package\s+([.\w]+)/
    @read_code.add_callback_head(pattern) do |m, data|
      data[:package] = _short_package.(m[1])
      true
    end

    pattern = /import\s+(static\s+)?((\w+(\.\w+)*)(\.\*)?)/
    @read_code.add_callback_head(pattern) do |m, data|
      (pkg = _short_package.(m[2])) and (data[:import] ||= []).push pkg
      true
    end

    @read_code.add_callback_head(/^\s*@(\w+.*)/) do |m, data|
      i = m[1].lstrip
      i.match(/"/) and i = %Q("#{i.gsub(/"/, '\\\\"')}")
      data[:anotation].push i
      true
    end

    @read_code.add_callback_tail(
    Utils::NestedPattern::KLASS_LINE) do |m, data|
      _extract_class_info(m, data)
    end

    pattern = /#{Utils::NestedPattern::FUNC_HEAD}{/
    @read_code.add_callback_tail(pattern) do |m, data|
      dt = (data[:function] ||= {})[m[:all].gsub(/\s+/, ' ')] = {}
      _set_anotation(dt, data)
      true
    end

    pattern = /#{Utils::NestedPattern::FUNC_HEAD};/
    @read_code.add_callback_head(pattern) do |m, data|
      if (klass = data[:class])
        if klass[:type] == 'interface'
          dt = (data[:function] ||= {})[m[:all].lstrip] = {}
          _set_anotation(dt, data)
          true
        end
      end
      false
    end
  end


  def _set_anotation(dt, data)
    (anotation = data[:anotation]).empty? and return
    dt[:anotation] = anotation
    data[:anotation] = []
  end


  def _extract_class_info(m, data)
    data[:class] and return
    _name = ->(m){ m[:klass].match(/^([A-Z]\w*)/)[1] }

    dt = data[:class] = {
      type: %Q("#{m[:type]}"),
      name: _name[m],
    }
    _set_anotation(dt, data)

    remain = m[:option] or return
    if m = remain.match(/extends\s+#{Utils::NestedPattern::KLASS}/)
      dt[:extends] = _name[m]
      remain = m.post_match
    end

    impl = []
    m = remain.match(/\s*implements\s+#{Utils::NestedPattern::KLASS}/)
    while m
      impl.push _name[m]
      m = m.post_match.match(/\s*,\s*#{Utils::NestedPattern::KLASS}/)
    end
    impl.empty? or dt[:implements] = impl
    true
  end


  def _extract(dn)
    out_data = {}
    @file_traverse.traverse(dn) do |fn|
      (File.basename(fn) == 'package-info.java') and next

      data = { anotation: [] }
      @read_code.exec(fn, data)
      (klass_info = data[:class]) or next

      dt = (out_data[data[:package]] ||= {})[klass_info[:name]] = {
        source: fn.match(/^#{dn}\/?(.*?)\/?#{File.basename(fn)}$/)[1],
        type:   klass_info[:type],
      }

      [ [klass_info, [:extends, :implements, :anotation]],
        [data,       [:import,  :function  ]],
      ].each do |(src, keys)|
        keys.each { |k| (x = src[k]) and dt[k] = x }
      end
    end

    _expand_package_name_in_klass_info(out_data)
    out_data
  end


  #
  # expand package names of import, extends and implements
  # which are in klass_info
  #
  def _expand_package_name_in_klass_info(data)
    klass_to_package = {}
    data.each do |package, aklass|
      aklass.each do |klass, klass_info|
        unless import = klass_info[:import]
          klass_info.delete(:extends)
          klass_info.delete(:implements)
          next
        end

        import.map! do |i|
          if m = i.match(/\.\*$/)
            data[pkg = m.pre_match].map do |k, _|
              (k.class == Symbol) ? nil : "#{pkg}.#{k}"
            end
          else i
          end
        end
        import.flatten!
        import.compact!

        klass_to_package.clear
        import.each do |i|
          klass_to_package[i.match(/\.([^.]+)$/)[1]] = i
        end

        if x = klass_to_package[klass_info[:extends]]
          klass_info[:extends] = x
        else klass_info.delete(:extends)
        end

        if implements = klass_info[:implements]
          impl = implements.map { |i| klass_to_package[i] }.compact
          if impl.empty? then klass_info.delete(:implements)
          else klass_info[:implements] = impl
          end
        end
      end
    end
  end


  def _print(data, f_out)
    data.each do |package, aklass|
      f_out.puts "#{package || '(none)'}:"
      aklass.each do |klass_name, klass_info|

        f_out.puts "  #{klass_name}:"
        klass_info.each do |field, dt|
          case dt
          when String
            f_out.puts "    #{field}: #{dt}"
          when Array
            f_out.puts "    #{field}:"
            dt.each { |i| f_out.puts "    - #{i}" }
          when Hash
            f_out.puts "    #{field}:"
            dt.each do |i, v|
              f_out.puts "      #{i}:"
              if anotation = v[:anotation]
                anotation.each { |d| f_out.puts "      - #{d}" }
              end
            end
          end
        end
        f_out.puts

      end
    end
  end
end


if(ARGV.size < 1)
  puts 'class relation extractor'
  puts "ruby #{$0} dir_name [fn_out]"

else
  dn, fn_out = ARGV
  ClassRelation.new.extract(dn, fn_out)
end

