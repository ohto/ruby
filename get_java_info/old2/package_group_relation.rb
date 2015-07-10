require 'yaml'
require 'set'
require 'pp'


class PackageGroup
public
  def initialize(fn_category)
    @category = {}
    _load_yaml(fn_category).each do |section, layer|
      pt = @category[section] = {}
      layer.each do |name, key|
        key = _key_pattern(key) or raise "wrong format: #{fn_category}"
        pt[name] = /((^|\.)#{key.gsub('.', '\.')})(\.|$)/
      end
    end
  end


  def extract(fn_in, fn_out)
    _print = case File.extname(fn_out)
    when '.yaml' then :_print_yaml
    when '.dot'  then :_print_dot
    else raise "unknown ext type (.yaml or .dot): #{fn_out}"
    end

    packages = _packages(_load_yaml(fn_in))
    odata    = _relation(packages, _categorize(packages))
    File.open(fn_out, 'w') { |f| send(_print, odata, f) }
  end


private
  def _key_pattern(key)
    case key
    when Array  then key.join('|')
    when String then key
    end
  end


  def _load_yaml(fn)
    File.exist?(fn) or raise "not exist: #{fn}"
    YAML.load_file(fn) rescue raise "yaml format error: #{fn}"
  end


  def _packages(package_base)
    odata = {}
    package_base.each do |package, aklass|
      aklass.delete('source').match(/test/) and next
      dt = odata[package] = Set.new

      aklass.each do |klass_name, klass_info|
        (klass_info['type'] == 'enum') and next
        (import = klass_info['import']) or next
        import.each { |i| dt.add i.match(/\.[^.]+$/).pre_match }
      end
    end
    odata
  end


  def _key(*params)
    params.join('.').to_sym
  end


  def _categorize(packages)
    odata = {}
    packages.each_key do |package|
      odata[package] = ->() {
        @category.each do |section, layer|
          layer.each do |name, pt|
            package.match(pt) and return _key(section, name)
          end
        end
        :other
      }.()
    end
    odata
  end


  def _relation(packages, category)
    odata = {}
    @category.each do |section, layer|
      layer.each_key do |name|
        odata[_key(section, name)] = Hash.new(0)
      end
    end
    odata[:other] = Hash.new(0)

    packages.each do |package, import|
      src = category[package] or next
      import.each do |i|
        (dist = category[i]) and odata[dist][src] += 1
      end
    end
    odata
  end


  def _print_yaml(odata, f_out)
    odata.each do |dest, imported|
      imported.empty? and next
      f_out.puts "#{dest}:"
      imported.sort.each { |(src, no)| f_out.puts "  #{src}: #{no}" }
      f_out.puts
    end
  end


  def _print_dot(odata, f_out)
    _get_section = ->(k) { k.to_s.match(/^([^.]+)/)[1] }
    inner = {}
    outer = []

    odata.each do |category, imports|
      section = _get_section.(category)
      unless section == 'other'
        inner_section = inner[section] ||= {}
        (inner_section[:nodes] ||= []).push category
      end

      imports.each_key do |i| (category == i) and next
        dt = []
        ((section == _get_section.(i)) ? dt : outer).push [i, category]
        dt.empty? or inner_section[:relations] = dt
      end
    end

    _print_pair = ->(pairs) do
      pairs.each do |(s, d)|
        f_out.puts %Q("#{s}" -> "#{d}")
      end
    end

    f_out.puts "digraph #{File.basename(__FILE__, '.rb')} {"
    f_out.puts 'newrank=true;'

    cluster_counter = 0
    inner.each do |section, info|
      f_out.puts "subgraph cluster#{cluster_counter += 1} {"
      f_out.puts %Q(label = "#{section}")
      info[:nodes].each { |node| f_out.puts %Q("#{node}") }
      _print_pair.(info[:relations])
      f_out.puts '}'
    end

    _print_pair.(outer)
    f_out.puts '}'
  end
end


if (ARGV.size < 3)
  puts "ruby #{$0} class.info.yaml category.yaml out]"
  puts 'out exp : .yaml | .dot'

else
  fn_in, fn_category, fn_out = ARGV
  PackageGroup.new(fn_category).extract(fn_in, fn_out)
end

