require 'set'
require 'yaml'
require 'pp'


module PackageImportsRelation
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
      source_base.each do |source, info|
        f_out.puts "#{source}:"
        f_out.puts '  package:'
        info['package'].each { |i| f_out.puts "  - #{i}" }

        if outer = info['outer']
          f_out.puts '  outer:'
          outer.each do |(s, a)|
            f_out.puts "    #{s}:"
            a.each { |i| f_out.puts "    - #{i}" }
          end

        end
        f_out.puts
      end
    end
  end
end


if (ARGV.size < 1)
  puts "ruby #{$0} package.imports.summary.yaml [out.yaml]"

else
  PackageImportsRelation.extract(*ARGV)
end

