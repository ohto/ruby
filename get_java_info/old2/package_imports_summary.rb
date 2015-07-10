require 'set'
require_relative 'extract_yaml'


module PackageImportsSummary
  class << self
    include ExtractYaml

  private
    def _cmp(i1, i2)
      [:outer, :inner, :package].each do |field|
        cmp = i1[field].size <=> i2[field].size
        (cmp != 0) and return cmp
      end
      return 0
    end


    def _extract(package_base, f_out)
      mid_data = {}
      package_base.each do |package, pkg_info|
        package_fn = package.tr('.', '/')
      end







      source_base = {}
      package_base.each do |package, pkg_info|
        package_fn = package.tr('.', '/')

        pkg_info.each do |type, aklass|
          aklass.each do |name, info|
            fn = info['source'].match(package_fn).pre_match
            dt = source_base[fn] ||= { package: [], import: Set.new }
            dt[:package].push package

            (import = info['import']) or next
            imp = dt[:import]
            import.each { |i| imp.add i.match(/([^.]+)$/)[1] }
          end
        end
      end

      source_base.each do |source, info|
        info[:inner] = []
        info[:outer] = {}
        info.delete(:import).each do |pkg|
          if info[:package].include?(pkg) then info[:inner].push pkg
          else
            src = source_base[pkg]['source']


info[:outer]





          src = package_base[package]['source']
          if (src == source) then info[:inner].push package
          else (info[:outer][src] ||= []).push package
          end
        end
      end




      source_base.each do |source, info|
        info[:inner] = []
        info[:outer] = {}
        info.delete(:imports).each do |package|
          src = package_base[package]['source']
          if (src == source) then info[:inner].push package
          else (info[:outer][src] ||= []).push package
          end
        end
      end

      source_base
    end


    def _print(odata, f_out)
      source_base.sort { |(_, i1), (_, i2)| _cmp(i1, i2) }
                 .each do |(source, info)|
        f_out.puts "#{source}:"
        f_out.puts '  package:'
        info[:package].each { |package| f_out.puts "  - #{package}" }

        unless (inner = info[:inner]).empty?
          f_out.puts '  inner:'
          inner.sort { |i1, i2| i1 <=> i2 }
               .each { |i| f_out.puts "  - #{i}" }
        end

        unless (outer = info[:outer]).empty?
          f_out.puts '  outer:'
          outer.sort { |(s1, _), (s2, _)| s1 <=> s2 }.each do |(s, a)|
            f_out.puts "    #{s}:"
            a.each.sort { |i1, i2| i1 <=> i2 }.each do |i|
              f_out.puts "    - #{i}"
            end
          end
        end

        f_out.puts
      end
    end
  end
end


PackageImportsSummary.extract('class.relation')

