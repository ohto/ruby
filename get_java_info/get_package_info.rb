require 'yaml'
require 'set'
require 'pp'


class PackageInfo
public
  def extract(fn_in, fn_out)
    odata = _packages(_load_yaml(fn_in))
    if (fn_out) then File.open(fn_out, 'w') { |f| _print(odata, f) }
    else _print(odata, STDOUT)
    end
  end


private
  def _load_yaml(fn)
    File.exist?(fn) or raise "not exist: #{fn}"
    YAML.load_file(fn) rescue raise "yaml format error: #{fn}"
  end


  def _packages(package_base)
    odata = {}
    package_base.each do |package, aklass|
      source = aklass.delete('source')
      source.match(/test/) and next

      dt = odata[source] ||= {
        package: Set.new,
        import:  Set.new,
      }

      aklass.each do |klass_name, klass_info|
        (klass_info['type'] == 'enum') and next
        dt[:package].add "#{package}.#{klass_name}"

        (import = klass_info['import']) or next
        d = dt[:import]
        import.each { |i| d.add i.match(/\.[^.]+$/).pre_match }
      end
    end

    odata
  end


  def _print(odata, f_out)
    odata.sort.each do |(source, pkg_info)|
      f_out.puts "#{source}:"

      [:package, :import].each do |key|
        (dt = pkg_info[key]) or next
        f_out.puts "  #{key}:"
        dt.sort.each { |i| f_out.puts "  - #{i}" }
      end
      f_out.puts
    end
  end
end


if (ARGV.size < 1)
  puts "ruby #{$0} class.info.yaml [out.yaml]"

else
  fn_in, fn_out = ARGV
  PackageInfo.new.extract(fn_in, fn_out)
end

