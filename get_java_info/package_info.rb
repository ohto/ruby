require 'optparse'
require 'yaml'
require 'set'
require 'pp'
require 'utils/yaml_helper'


class PackageInfo
  IMPORT_TYPE = {
    interface: {
      group: %w(import_interface import_emun),
      color: :blue,
    },
    class: {
      group: %w(import_class),
      color: :red,
    },
  }.freeze


public
  def extract(opt)
    odata = _extract(Utils::YamlHelper.read(opt[:input]), opt)
    case (ofn = opt[:output]) ? File.extname(ofn) : nil
    when NilClass then Utils::YamlHelper.write(odata)
    when '.yaml'  then Utils::YamlHelper.write(odata, ofn)
    when '.dot'
      File.open(ofn, 'w') { |f| _print_dot(odata, f, opt) }
    else raise "unknown out format: #{ext}"
    end
  end


private
  def _get_package(package_base, impl)
    until(impl.empty?)
      m = impl.match(/\.([^.]+)$/) or return nil
      package_base[pkg = m.pre_match] and return pkg
      impl = pkg
    end
    nil
  end


  def _get_target_match(opt)
    target = opt[:target_package] or return ->(i) { true }
    opt[:with_match] ? ->(i) { i.match(target) } : ->(i) { i == target }
  end


  def _extract(package_base, opt)
    odata = {}
    _target_match = _get_target_match(opt)

    package_base.each do |package, pkg_info|
      project = pkg_info.delete('source').match(/^([^\/]+)\//)[1]
      _target_match[project] or next

      dt = (odata[project] ||= {})[package] = {}
      pkg_info.each do |klass_name, klass_info|
        klass_info.nil? and next

        if klass_name == 'source'
          dt[:source] = klass_info
          next
        end

        IMPORT_TYPE.each do |category, itype|
          d = dt[category] ||= Set.new
          itype[:group].each do |type|
            aimp = klass_info[type] or next
            aimp.each do |i|
              i = _get_package(package_base, i) or next
              i == package or d.add i
            end
          end
        end
      end
    end

    packages = []
    odata.each { |_, project_info| packages += project_info.keys }
    odata.each do |_, project_info|
      project_info.each do |_, pkg_info|
        pkg_info.each do |imp, aimp|
          aimp.keep_if { |i| packages.include?(i) }
          aimp.empty? and pkg_info.delete(imp)
        end
      end
    end
    odata
  end


  def _subgroup(package, n)
    m = package.split('.')
    (n <= m.size) ? m[0,n].join('.') : nil
  end


  def _get_color(odata, range)
    count = Hash.new(0)
    odata.each do |_, project_info|
      project_info.each do |_, import_info|
        import_info.empty? and next
        import_info[:class].each { |i| count[i] += 1 }
      end
    end
    count.empty? and return count

    if    (0.5 < range) then range = 0.5
    elsif (range < 0.1) then range = 0.1
    end

    sorted = count.sort { |(_, v1), (_, v2)| v1 <=> v2 }
    size   = count.size
    lower  = (size *      range ).to_i
    upper  = (size * (1 - range)).to_i

    color = {}
    (0    ..(lower - 1)).each { |i| color[sorted[i][0]] = '#9999FF' }
    (upper..(size  - 1)).each { |i| color[sorted[i][0]] = '#FF9999' }
    color
  end


  def _print_dot_project(odata, f_out, &blk)
    odata.size == 0 and return
    f_out.puts "digraph #{File.basename(__FILE__, '.rb')} {"
    f_out.puts 'graph [rankdir=RL]'

    if(odata.size == 1) then blk.(odata.first[1])
    else
      odata.each do |project, project_info|
        f_out.puts %Q(subgraph "cluster_#{project}" {)
        f_out.puts %Q(label = "#{project}")
        blk.(project_info)
        f_out.puts '}'
      end
    end
    f_out.puts '}'
  end


  def _print_dot(odata, f_out, opt)
    color    = _get_color(odata, opt[:range] || 0.1)
    _imports = if opt[:class_only]
      ->(info, &blk) { a = info[:class] and blk.(a, '') }
    else
      ->(info, &blk) do
        info.each do |type, a|
          blk.(a, " [color = #{IMPORT_TYPE[type][:color]}]")
        end
      end
    end

    _print_dot_project(odata, f_out) do |project_info|
      sub = _get_subgroup(project_info)
      _print_dot_package(sub, color, f_out)
      _print_dot_relation(project_info, _imports, f_out)
    end
  end


  def _print_dot_relation(project_info, _imports, f_out)
    project_info.each do |package, import_info|
      _imports.(import_info) do |imports, color|
        imports.each do |i|
          f_out.puts %Q("#{package}" -> "#{i}"#{color})
        end
      end
    end
  end


  def _get_subgroup(project_info)
    sub_package = {}
    project_info.each do |package, _|
      sub = sub_package
      a = package.split('.')
      last = a.pop.to_sym
      a.each do |s|
        s = s.to_sym
        case sub[s]
        when NilClass  then sub[s] = {}
        when TrueClass then sub[s] = {nil => true}
        end
        sub = sub[s]
      end

      if sub[last].class == Hash then sub[last][nil] = true
      else sub[last] = true
      end
    end
    sub_package
  end


  def _print_dot_vertex(i, color, f_out)
    f_out.puts (c = color[i]) ?
      %Q("#{i}" [style = filled, fillcolor = "#{c}"]) : %Q("#{i}")
  end


  def _print_dot_package(sub, color, f_out, base = nil)
    sub.each do |package, sub_package|
      package.nil? and next
      name = base.nil? ? package.to_s : "#{base}.#{package}"

      if sub_package == true
        _print_dot_vertex(name, color, f_out)
        next
      end

      if sub_package.size == 1
        k, v = sub_package.first
        d = {"#{package}.#{k}".to_sym => v}
        m = (v.class == Hash) ? base : name
        _print_dot_package(d, color, f_out, m)
        next
      end

      f_out.puts %Q(subgraph "cluster_#{name}" {)
      f_out.puts %Q(label = "#{name}")

      sub_package[nil] and _print_dot_vertex(name, color, f_out)
      _print_dot_package(sub_package, color, f_out, name)

      f_out.puts '}'
      f_out.puts
    end
  end
end


opts = {
  input:          'class.info.sum.yaml',
  target_package: 'company-spreadsheet',
  subgroup_level:  2,
  range:           0.1,
}

OptionParser.new do |opt|
  opt.on('-i','--input=VALUE', 'class.info.yaml') do |v|
    opts[:input] = v
  end

  opt.on('-o','--output=VALUE', '.yaml or .dot') do|v|
    opts[:output] = v
  end

  opt.on('-t','--target_package=VALUE',
         'string which include package name') do |v|
    opts[:target_package] = v
  end

  opt.on('-m','--with_match',
         'target package is included string <target_package>') do |v|
    opts[:with_match] = v
  end

  opt.on('-c','--class_only',
         'display class imported only') do |v|
    opts[:class_only] = v
  end

  opt.on('-s','--subgroup_level=VALUE', 'larger than 1') do |v|
    opts[:subgroup_level ] = v.to_i
  end

  opt.on('-r','--range=VALUE',
         'colored range from 0.1 to 0.5') do |v|
    opts[:range] = v.to_f
  end

  opt.parse!(ARGV)
end


puts 'params:'
opts.each { |k, v| puts "  #{k}: #{v}" }
PackageInfo.new.extract(opts)

