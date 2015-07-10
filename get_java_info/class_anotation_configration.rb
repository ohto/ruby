require 'optparse'
require 'set'
require 'pp'
require 'utils/yaml_helper'


class PackageInfo
  PROJECT_HEAD = 'com.worksap.company.framework'

public
  def extract(opt = {})
    odata = _extract(Utils::YamlHelper.read(opt[:input]), opt)
    if opt[:dump]
      Utils::YamlHelper.write(odata, opt[:output])
      return
    end

    if ofn = opt[:output]
      File.open(ofn, 'w') { |f| _print(odata, f) }
    else _print(odata, STDOUT)
    end
  end


private
  def _extract(package_base, opt)
    _anotation_finder = ->(a, anotation) do
      a and a.each do |i|
        (i.match(/^\w+/)[0] == anotation) and return true
      end
      false
    end

    odata = {}
    package_base.each do |package, pkg_info|
      pkg_info.each do |klass_name, klass_info|
        name = [package, klass_name].join('.')

        a = klass_info['anotation']
        _anotation_finder.(a, 'Configuration') or next
        dt = odata[name] = []

        fa = klass_info['function'] or next
        fa.each do |fn, a|
          _anotation_finder.(a, 'Bean') or next
          dt.push fn.match(/(\w+)\s*\(/)[1]
        end
      end
    end
    odata
  end


  def _print(odata, f)
    odata.sort.each do |(klass_name, fa)|
      if fa.empty? then f.puts klass_name
      else fa.each { |i| f.puts [klass_name, i].join(', ') }
      end
    end
  end
end


opts = {
  input: 'class.info.yaml',
}

OptionParser.new do |opt|
  opt.on('-i','--input=VALUE', 'class.info.yaml') do |v|
    opts[:input] = v
  end

  opt.on('-o','--output=VALUE', 'out.yaml') do|v|
    opts[:output] = v
  end

  opt.on('-d','--dump', 'dump to yaml') do|v|
    opts[:dump] = v
  end

  opt.parse!(ARGV)
end


PackageInfo.new.extract(opts)

