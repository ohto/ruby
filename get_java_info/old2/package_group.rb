require 'yaml'
require 'set'


class PackageGroup
public
  def initialize(fn_category)
    @category = {}
    _load_yaml(fn_category).each do |section, layer|
      pt = @category[section] = {}
      layer.each do |name, key|
        (key.class <= Array) and key = key.join('|')
        pt[name] = /((^|\.)#{key.gsub('.','\.')})(\.|$)/
      end
    end
  end


  def extract(fn_in, fn_out)
    odata = _extract(_source_base(_load_yaml(fn_in)))
    if (fn_out) then File.open(fn_out, 'w') { |f| _print(odata, f) }
    else _print(odata, STDOUT)
    end
  end


private
  def _load_yaml(fn)
    File.exist?(fn) or raise "not exist: #{fn}"
    YAML.load_file(fn) rescue raise "yaml format error: #{fn}"
  end


  def _source_base(package_base)
    odata = {}
    package_base.each do |package, pkg_data|
      pkg_data.each do |type, aklass|
        aklass.each do |name, info|
          source = info['source']
          source.match(/test/) and next
          (odata[source] ||= Set.new).add package
        end
      end
    end
    odata
  end


  def _extract(source_base)
    odata = {}
    @category.each do |section, layer|
      dt = odata[section] = {}
      layer.each { |name, key| dt[name] = Set.new }
    end
    odata[:other] = Set.new

    source_base.each do |_, packages|
      packages.each do |package|
        ->() {
          @category.each do |section, layer|
            layer.each do |name, pt|
              package.match(pt) and return odata[section][name]
            end
          end
          odata[:other]
        }.().add package
      end
    end

    odata
  end


  def _print(odata, f_out)
    odata.each do |section, layer|
      f_out.puts "#{section}:"

      case layer
      when Set
        layer.sort.each { |d| f_out.puts "- #{d}" }

      when Hash
        layer.each do |name, dt|
          unless dt.empty?
            f_out.puts "  #{name}:"
            dt.to_a.sort.each { |d| f_out.puts "  - #{d}" }
          end
          f_out.puts
        end
      end

      f_out.puts
    end
  end
end



if (ARGV.size < 2)
  puts "ruby #{$0} class.info.yaml package.category.yaml [out.yaml]"

else
  fn_in, fn_category, fn_out = ARGV
  obj = PackageGroup.new(fn_category)
  obj.extract(fn_in, fn_out)
end

