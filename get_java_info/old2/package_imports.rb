require 'set'
require_relative 'extract_yaml'


module PackageImports
  class << self
    include ExtractYaml

  private
    def _extract(package_base, f_out)
      odata = {}
      package_base.each do |package, pkg_data|

        imp = odata[package] = { imports: Set.new }
        pkg_data.each do |type, aklass|
          aklass.each do |name, info|
            unless imp[:source]
              pkg = package.match(/^\(.*\)$/) ? '' : package.tr('.', '/')
              imp[:source] = info['source'].match(/^(.+)#{pkg}\/\w+\.java$/)[1]
            end

            d = imp[:imports]
            (info['import'] || []).each do |i|
              data[c = i.match(/^(.+)\.\w+$/)[1]] and d.add _package_short(c)
            end
          end
        end
      end
      odata
    end


    def _print(odata, f_out)
      odata.sort { |(p1, _), (p2, _)| p1 <=> p2 }
             .each do |(package, imp)| f_out.puts "#{package}:"

        f_out.puts "  source: #{imp[:source]}"
        unless (d = imp[:imports]).empty?
          f_out.puts '  imports:'
          imp[:imports].sort { |i1, i2| i1 <=> i2 }
                       .each { |i| f_out.puts "  - #{i}" }
        end
        f_out.puts
      end
    end
  end
end


PackageImports.extract('class.relation')

