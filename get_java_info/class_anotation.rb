require 'optparse'
require 'set'
require 'pp'
require 'utils/yaml_helper'


class PackageInfo
public
  def extract(opt = {})
    odata = _extract(Utils::YamlHelper.read(opt[:input]), opt)
    Utils::YamlHelper.write(odata, opt[:output])
  end


private
  def _extract(package_base, opt)
    _anotation_finder = if anotation = opt[:anotation]
      ->(a) { a and a.include?(anotation) }
    else ->(a) { a }
    end

    odata, dt = {}, {}
    package_base.each do |package, pkg_info|
      dt[:source] = pkg_info.delete('source')

      pkg_info.each do |klass_name, klass_info|
        _anotation_finder.(klass_info['anotation']) or next
        d = dt[klass_name] = {}
        [
#         :type,
         :anotation,
#         :import,
        ].each { |t| d[t] = klass_info[t.to_s] }
      end

      dt.size < 2 and next
      odata[package] = dt
      dt = {}
    end
    odata
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

