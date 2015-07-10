require 'optparse'
require 'set'
require 'pp'
require 'utils/yaml_helper'


class GetAnotationList
  FIELDS = [:class, :function].freeze

public
  def extract(opt = {})
    odata = _extract(Utils::YamlHelper.read(opt[:input]))
    Utils::YamlHelper.write(odata, opt[:output])
  end


private
  def _extract(package_base)
    odata = {}
    FIELDS.each { |k| odata[k] = Set.new }

    package_base.each do |package, pkg_info|
      pkg_info.delete('source')
      pkg_info.each do |klass_name, klass_info|
        _set_anotation(odata[:class], klass_info['anotation'])
        h  = klass_info['function'] or next
        of = odata[:function]
        h.each { |fn, a| _set_anotation(of, a) }
      end
    end

    FIELDS.each { |k| odata[k] = odata[k].sort }
    odata
  end


  def _set_anotation(dt, a)
    a and a.each { |i| dt.add i.match(/^\w+/)[0] }
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

  opt.parse!(ARGV)
end


GetAnotationList.new.extract(opts)

