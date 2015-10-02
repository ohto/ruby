require 'yaml'
require 'fileutils'
require 'rexml/parsers/ultralightparser'
require 'pp'


class XmlFormatter
  def initialize(opt = {})
    @ext    = opt[:ext]    || '.xml'
    @tab    = opt[:tab]    || ' '
    @indent = opt[:indent] || 2
    @format = YAML.load_file(opt[:format])
  rescue
    @format = nil
  end

  def transfer(in_dn, out_dn)
    File.exist?(in_dn) or raise "no exist: #{in_dn}"
    @in_dn  = in_dn
    @out_dn = out_dn
    _traverse('')
  end


private
  def _traverse(rdn)
    dn = File.join(@in_dn, rdn)
    (bn = File.basename(dn)).match(/^\./) and return
    if File.directory?(dn)
      Dir.foreach(dn) { |c| _traverse(File.join(rdn, c)) }

    elsif File.extname(bn) == @ext
      hash = File.open(dn) { |f| _get_hash(f) } or return
      ofn  = File.join(@out_dn, rdn)
      FileUtils.mkdir_p(File.dirname(ofn))
      File.open(ofn, 'w') { |f| _out_xml(f, hash) }
    end
  end


  class Elm
    attr_reader :data, :ctrl
    def self.set_format(format)
      @@format = format
    end

    def initialize(doc, opt = {})
      @ctrl = {}
      @data = {}
      [:property, :head_text, :no_order].each do |key|
        t = opt[key] and @ctrl[key] = t
      end
      _get(doc)
    end

    def out(f, format)
      @@f = f
      _out(format, 0)
    end

    def out_element(k, format, indents)

    end

#==========================

  private
    def _out(format, indents)
      unless _out_hash(format)
        format.class == Array and format.each do |key|
          _out_hash[key] or _out_element(key, elm, nil)
        end
        elm.each { |k, v| _out_element[k, v, nil] }
      end
      text = ctrl[:text] and puts "#{@tab * indents}#{text}"
    end

    def _out_hash(hash)
      hash.class == Hash or return false
      hash.each { |k, fmt| @data[k].out_element(k fmt) }
      true
    end

    def _out_element

    end



    def out(f, format, indents = 0)
pp elm
    ctrl = elm.delete(:ctrl)

    _out_element = ->(key, value, fmt) do
      e = value.delete(key) or return
      _out_elm(f, key, e, fmt, ctrl, indents)
    end

    _out_hash = ->(hash) do
      hash.class == Hash or return false
      hash.each { |k, fmt| _out_element[k, elm, fmt] }
      true
    end

p 1
    unless _out_hash[format]
      format.class == Array and format.each do |key|
        _out_hash[key] or _out_element[key, elm, nil]
      end
      elm.each { |k, v| _out_element[k, v, nil] }
    end
    text = ctrl[:text] and puts "#{@tab * indents}#{text}"
  end


  private
    def _get(doc)
      text = []
      no_order = false

      while elm = doc.shift
        case elm.shift
        when :text then text.push elm[0].strip
        when :comment
          text.push "<!--#{c = elm[0]}-->"
          c.match(/\s*@NO_ORDER/) and no_order = true

        when :start_element
          elm.shift # delete parent information
          key = elm.shift
          property = elm.shift
          (@data[key] ||= []).push Elm.new(elm,
            property:  property,
            head_text: (t = text.join).empty? ? nil : t,
            no_order:  no_order,
          )
          text.clear
          no_order = false
        end
      end
      (t = text.join).empty? or @ctrl[:text] = t
    end
  end


  def _get_hash(f)
    parser = REXML::Parsers::UltraLightParser.new(f.read)
    doc = parser.parse or return nil
    doc.empty? and return nil

    head = if doc[0][0] == :xmldecl
      h = doc.shift
      {
        version:    h[1],
        encoding:   h[2],
        standalone: h[3],
      }
    else nil
    end
    [head, Elm.new(doc)]
  end


  def _out_elm_tag(f, key, elm, ctrl, indents, &blk)
    space = @tab * indents
    t = ctrl[:head_text] and puts "#{space}#{t}"

    print "#{space}<#{key}"
    ctrl[:property].each do |pk, pv|
      pv = pv.include?('"') ? "'#{pv}'" : %Q("#{pv}")
      print " #{pk}=#{pv}"
    end

    if elm.empty? then puts '/>'
    else
      puts '>'
      blk[elm]
      puts "#{space}</#{key}>"
    end
  end


  def _cmd(a, b, format)
    _get = ->(x, i) do
      xi = x[i] or return ''
      1 < xi.size and return '' # is elements
      xi[:ctrl][:text] || ''
    end

pp 'cmd ------------------'
pp format
pp _get[a,0]
pp _get[b,0]
exit

    format.each do |i|
      if ai = _get[a,i] then (bi = _get[b,i])? ai <=> bi : 1
      else _get[b,i] ? -1 : 0
      end
      r == 0 or return r
    end
    0
  end


  def _out_elm(f, key, elm, format, ctrl, indents)
    inext = indents + @indent
    unless ctrl[:no_order]
      case format
      when Array
pp 'Array'
        elm.sort! { |a, b| _cmd(a, b, format) }

      when '_SORT_BY_VALUE_'
pp 'sv'
        elm.sort! { |a, b| a[:text] <=> b[:text] }

      when '_SORT_BY_KEY_'
pp 'sk'
        elm.each do |e|
          _out_elm_tag(f, key, e, ctrl, indents) do |val|
            e.sort { |(k1,_), (k2,_)| k1 <=> k2 }.each do |(k,v)|
              c = v.delete(:ctrl)
              _out_elm(f, k, v, nil, c, inext)
              text = c[:text] and puts "#{@tab * indents}#{text}"
            end
          end
        end
        return
      end
    end

pp 'other'
    elm.each do |e|
p 10
      _out_elm_tag(f, key, e, e.delete(:ctrl), indents) do |v|
p 11
        _out_elms(f, v, format, inext)
p 12
      end
    end
  end


  def _out_elms(f, elm, format, indents = 0)
pp elm
    ctrl = elm.delete(:ctrl)

    _out_element = ->(key, value, fmt) do
      e = value.delete(key) or return
      _out_elm(f, key, e, fmt, ctrl, indents)
    end

    _out_hash = ->(hash) do
      hash.class == Hash or return false
p 3
      hash.each { |k, fmt| _out_element[k, elm, fmt] }
p 4
      true
    end

p 1
    unless _out_hash[format]
pp 'hash'

      format.class == Array and format.each do |key|
        _out_hash[key] or _out_element[key, elm, nil]
      end
      elm.each { |k, v| _out_element[k, v, nil] }
    end
    text = ctrl[:text] and puts "#{@tab * indents}#{text}"
  end


  def _out_xml(f, hash)
    if head = hash[0]
      print '<?xml'
      [:version, :encoding, :standalone].each do |key|
        d = head[key] and print %Q( #{key}="#{d}")
      end
      puts '?>'
    end
    hash[1].out(f, @format)
  end
end


if ARGV.size < 2 then puts "#{$0} in_dir/file out_dir/file [format]"
else
  in_dn, out_dn, format = ARGV
  formatter = XmlFormatter.new(format: format)
  formatter.transfer(in_dn,out_dn)
end


