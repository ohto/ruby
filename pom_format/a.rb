require 'pp'
require 'xmlsimple'

class ConvertXML
  def initialize(opt = {})
   @space = opt[:space] || ' '
   @times = opt[:times] || 2
   @sort  = opt[:sort]  || []
  end


  def conver(fn_in, fn_out)
    xml  = REXML::Document.new(File.open(fn_in))
    hash = XmlSimple.xml_in(xml, ContentKey:"__content__")
puts    xml  = XmlSimple.xml_out(hash, ContentKey:"__content__")
  end


private
  def _write(f, data, indent)
    space = @space * indent

    data.each do |k, v|
      s = @sort[k] and v = s[v]

      case v
      when Hash 
        f.puts "#{space}<#{k}>"
        _write(f, v, indent + @times)
        f.puts "#{space}</#{k}>"

      when Array
        v.each do |c|
          if c.class == Hash
            f.puts "#{space}<#{k}>"
            _write(f, c, indent + @times)
            f.puts "#{space}</#{k}>"
          else f.puts "#{space}<#{k}>#{c}</#{k}>"
          end

        end
      else
        v and f.puts "#{space}<#{k}>#{v}</#{k}>"
      end
    end
  end


  def _to_hash(elm)
    value = if elm.has_elements?
      children = {}
      elm.each_element do |e|
        children.merge!(_to_hash(e)) do |k, v1, v2|
          v1.class == Array ? v1 << v2 : [v1, v2]
        end
      end
      children
    else
      elm.text
    end
    { elm.name.to_sym => value }
  end
end


#DEPENDENCY_ORDER = [:id, :version]
DEPENDENCY_ORDER = [:groupIdid, :artifactId, :version, :scope]

def hash_order(h, order)
  ret = {}
  order.each do |k|
    v = h.delete(k) and ret[k] = v
  end
  h.each { |k, v| ret[k] = v }
  ret
end


order = {}
order[:dependencies] = ->(h) do
  ret = h[:dependency].map { |d| hash_order(d, DEPENDENCY_ORDER) }
  ret.sort! { |a, b| a[:id] <=> b[:id] }
  ret
end

order[:properties] = ->(h) do
  ret = {}
  h.sort.each { |(k, v)| ret[k] = v }
  ret
end


c = ConvertXML.new(sort: order)
c.conver('t.pom', 'out.xml')

