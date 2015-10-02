require 'yaml'
require 'xmlsimple'
require 'pp'


def get(fn)
pp  hash = YAML.load_file(fn)

end

if ARGV.size < 1 then puts "#{$0} fn.yaml"
else
  fn = ARGV[0]
  get(fn)
end


