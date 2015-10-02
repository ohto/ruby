require 'rexml/document'
require 'pp'


class ConvertXML
  def initialize(opt = {})
    @space = opt[:space] || ' '
    @times = opt[:times] || 2
    @order = opt[:order] || {}
  end

  def convert(fn_in, fn_out)
    doc  = REXML::Document.new(File.open(fn_in))
    hash = _to_hash(doc.root)

_order!(hash)
pp hash
    File.open(fn_out, 'w') { |f| _out_xml(f, hash) }
  end


private
  def _order!(elm)
    elm.each do |key, value|
      value.class == Hash or next
      _sort(value)
      _order!(value)
    end
  end

  def _get_order(elm)
    comments = elm[:_comments] or return nil
    comments.each do |c|
      m = c.strip.match(/order\s+(.+)/) and return m[1]
    end
    nil
  end


  def _sort(elm)
    order = _get_order(elm) or return
    case order
    when /^\w+$/
      order = order.to_sym
      elm.each do |key, value|
        value.class == Array or next
        value.sort { |a, b| a[order][:_] <=> b[order][:_] }
      end

    when /\[(\w+(\s*,\s*\w+)*)\]/
      order = $1.split(/\s*,\s*/).map { |i| i.to_sym }
      elm.each do |key, value|
        key == :_comments and next
        value.class == Array or next
        value.sort! do |a, b|
          order.each do |i|
            if ai = a[i]
              (bi = b[i]) or next 1
              (c = ai[:_] <=> bi[:_]) == 0 or next c
            else next (b[i] ? -1 : 0)
            end
          end
          0
        end
      end

    else return
    end
  end


  def _out_elm(f, key, value, indent)
    indents   = @space * indent
    attribute = value.delete(:_attributes)
    comments  = value.delete(:_comments)
    _put_comments = ->() do
      spc = @space * (indent + @times)
      comments.each { |c| f.puts "#{spc}<!--#{c}-->" }
    end

    f.print "#{indents}<#{key}"
    if attribute
      attribute.each do |k, v|
        f.print " #{k}=#{v.include?('"') ? "'#{v}'" : %Q("#{v}")}"
      end
    else
    end

    if value.empty? then f.puts '/>'
    else
      f.puts '>'
      comments and _put_comments.()
      _out_xml(f, value, indent + @times)
      f.puts "#{indents}</#{key}>"
    end
  end


  def _out_xml(f, elm, indent = 0)
    elm.each do |key, value|
      case value
      when Hash then _out_elm(f, key, value, indent)
      when Array then value.each { |v| _out_elm(f, key, v, indent) }
      else value.empty? or f.puts "#{@space * indent}#{value}"
      end
    end
  end


  def _to_hash(elm)
    value = {}
    elm.has_attributes? and value[:_attributes] = elm.attributes
    unless (c = elm.comments).empty?
      value[:_comments] = c.map { |e| e.string.strip }
    end

    if elm.has_elements?
      elm.each_element do |e|
        value.merge!(_to_hash(e)) do |k, v1, v2|
          v1.class == Array ? v1 << v2 : [v1, v2]
        end
      end
    else
      e = elm.text and value[:_] = e.strip
    end
    { elm.name.to_sym => value }
  end
end


if ARGV.size < 1
  puts "#{$0} in_file out_file"
else
  in_fn, out_fn = ARGV
  order = {}
  c = ConvertXML.new(order: order)
  c.convert(in_fn, out_fn || 'out.xml')
end


