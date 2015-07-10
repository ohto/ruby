require 'yaml'
require 'set'
require 'pp'


class SummarizeClassInfo
public
  def summarize(fn_in, fn_out)
    odata = _summarize(_load_yaml(fn_in))
    if (fn_out) then File.open(fn_out, 'w') { |f| _print(odata, f) }
    else _print(odata, STDOUT)
    end
  end


private
  def _load_yaml(fn)
    File.exist?(fn) or raise "not exist: #{fn}"
#    YAML.load_file(fn) rescue raise "yaml format error: #{fn}"
    YAML.load_file(fn)
  end


  def _get_type(package_base, impl)
    until(impl.empty?)
      m = impl.match(/\.([^.]+)$/) or return nil
      if package = package_base[pkg = m.pre_match]
        type = package[m[1]] and return type['type']
      end
      impl = pkg
    end
    nil
  end


  def _summarize(package_base)
    odata = {}
    package_base.each do |package, aklass|
      source = aklass.delete('source')
      pkg = odata[package] = {source: source}

      aklass.each do |klass_name, klass_info|
        import = klass_info['import'] or next
        dt = pkg[klass_name] = {}
        import.each do |i|
          t = _get_type(package_base, i) or next
          t = "import_#{t.match(/@?/).post_match}".to_sym
          (dt[t] ||= []).push i
        end
      end
    end
    odata
  end


  def _print(odata, f_out)
    odata.each do |package, aklass|
      f_out.puts "#{package}:"
      aklass.each do |klass_name, klass_info|
        if klass_name.class == Symbol
          f_out.puts "  #{klass_name}: #{klass_info}"
          next
        end

        f_out.puts "  #{klass_name}:"
        klass_info.each do |type, aimp|
          f_out.puts "    #{type}:"
          aimp.each { |i| f_out.puts "    - #{i}" }
        end
      end
    end
  end
end


if (ARGV.size < 1)
  puts "ruby #{$0} class.info.yaml [out.yaml]"

else
  fn_in, fn_out = ARGV
  SummarizeClassInfo.new.summarize(fn_in, fn_out)
end

