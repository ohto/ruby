require_relative 'extract_yaml'


module ClassRelationImprementsDot
  class << self
    include ExtractYaml
    NODE_COLOR = {
      'interface' => '#0088ff',
      'enum'      => '#ff8800',
    }

  private
    def _extract(package_base)
      no, odata = 0, {}
      f_out.puts 'digraph class_imprements_relation {'
      package_base.each do |pkg, pkg_data|
        pkg_data.each do |type, dt|
          dt.each do |name, info|
            d = odata["#{pkg}.#{name}".to_sym] = { no: no += 1 }
            if color = NODE_COLOR[type]
              f_out.puts %Q("#{no}"[fillcolor="#{color}", style="filled"])
            end
            (impl = info['imprements']) and d[:imprements] = impl
          end
        end
      end
      odata
    end


    def _print(odata, f_out)
      odata.each do |name, info|
        imprements = info[:imprements] or next

        s = info[:no]
        imprements.map { |i|
          (d = odata[i.to_sym]) ? d[:no] : nil
        }.compact.each do |i|
          f_out.puts "#{i} -> #{s}"
        end
      end

      f_out.puts '}'
    end

  end
end


ClassRelationImprementsDot.extract('package.imports')

