require 'optparse'
require 'set'
require 'pp'
require 'utils/yaml_helper'


class PackageInfo
  PROJECT_HEAD = 'com.worksap.company.framework'

public
  def extract(opt = {})
    odata = _extract(Utils::YamlHelper.read(opt[:input]), opt)
    if ofn = opt[:output]
      File.open(ofn, 'w') { |f| _print(odata, f) }
    else _print(odata, STDOUT)
    end
  end


private
  def _extract(package_base, opt)
    _anotation_finder = if anotation = opt[:anotation]
      ->(a) do
        a and a.each do |i|
          (i.match(/^\w+/)[0] == anotation) and return true
        end
        false
      end
    else ->(a) { a }
    end

    odata = {}
    package_base.each do |package, pkg_info|
      pkg_info.each do |klass_name, klass_info|
        name = [package, klass_name].join('.')
        _anotation_finder.(klass_info['anotation']) and odata[name] = ['']
        fa = klass_info['function'] or next

        fa.each do |fn, a|
          _anotation_finder.(a) or next
          (odata[name] ||= []).push fn
#          (odata[name] ||= []).push fn.match(/\s*\(/).pre_match
        end
      end
    end
    odata
  end


  def _print(odata, f)
    odata.sort.each do |(klass_name, fa)|
      fa.each { |fn| f.puts "#{klass_name}, #{fn}" }
    end
  end
end


opts = {
  input:     'class.info.yaml',
  anotation: 'Configuration',
}

OptionParser.new do |opt|
  opt.on('-i','--input=VALUE', 'class.info.yaml') do |v|
    opts[:input] = v
  end

  opt.on('-o','--output=VALUE', 'out.yaml') do|v|
    opts[:output] = v
  end

  opt.on('-a','--anotation=VALUE', 'anotation without "@"') do |v|
    opts[:anotation] = v
  end

  opt.parse!(ARGV)
end


PackageInfo.new.extract(opts)

