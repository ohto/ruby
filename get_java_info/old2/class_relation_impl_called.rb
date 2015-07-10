require_relative 'extract_yaml'


module ClassRelationImplCalled
  class << self
    include ExtractYaml

  private
    def _extract(package_base)
      odata = {}
      package_base.each do |package, pkg_data|
        pkg_data.each do |type, aklass|
          aklass.each do |name, info|
            import = info['import'] or next
            import = import.map { |i|
              i.match(/\.impl\./) ? i : nil
            }.compact

            import.empty? and next
            odata["#{package}.#{name}"] = {
              type:   type.to_sym,
              source: info['source'],
              import: import,
            }
          end
        end
      end
      odata
    end


    def _print(odata, f_out)
      sum = { class: 0, interface: 0 }
      odata.each do |name, info|
        sum[type = info[:type]] += 1

        f_out.puts "#{name}:"
        f_out.puts "  type: #{type}"
        f_out.puts "  source: #{info[:source]}"
        f_out.puts '  import:'
        info[:import].each { |i| f_out.puts "  - #{i}" }
        f_out.puts
      end

      puts 'number of vioration'
      sum.each { |type, count| puts "#{type}: #{count}" }
    end
  end
end


ClassRelationImplCalled.extract('class.relation')

