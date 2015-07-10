require 'yaml'
require 'pp'


module ExtractYaml
public
  def extract (inf_type)
    fn_in, fn_out = ARGV
    fn_in or _man(inf_type)

    odata = _extract(_load_yaml(fn_in))
    if (fn_out) then File.open(fn_out, 'w') { |f| _print(odata, f) }
    else _print(odata, STDOUT)
    end
  end


private
  def _load_yaml(fn)
    File.exist?(fn) or raise "not exist: #{fn}"
    YAML.load_file(fn) rescue raise "yaml format error: #{fn}"
  end

  def _man(inf_type)
    exp = $0.match(/_dot/) ? 'dot' : 'yaml'
    puts "ruby #{$0} #{inf_type}.yaml [out.#{exp}]"
    exit
  end
end

