require 'set'
require 'yaml'
require 'pp'


module PackageImportsRelationToDot
  class << self
  public
    def extract(fn_in, fn_out = nil)
      File.exist?(fn_in) or return
      (data = YAML.load_file(fn_in)) rescue puts "yaml format error: #{fn}"
      unless (fn_out) then _extract(data, STDOUT)
      else File.open(fn_out, 'w') { |f| _extract(data, f) }
      end
    end


  private
    def _extract(source_base, f_out)
      hash = {}
      source_base.keys.each_with_index { |k, i| hash[k] = i }

      f_out.puts 'digraph package_group_relation {'
      source_base.each do |source, info|
        outer = info['outer'] or next
        outer.each_key do |s|
          f_out.puts %Q(  "#{hash[s]}" -> "#{hash[source]}")
        end
      end
      f_out.puts '}'
    end
  end
end


if (ARGV.size < 1)
  puts "ruby #{$0} package.imports.summary.yaml [out.dot]"

else
  PackageImportsRelationToDot.extract(*ARGV)
end

