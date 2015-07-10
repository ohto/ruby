class ReadCodeJava2
public
  class ReadException < Exception; end


  @@LINE_COMMENT = /\s*\/\//
  @@BLACKET = {
    '(' => ')',
    '{' => '}',
    '<' => '>',     # for template type
    '/\*' => '\*/', # for comment
  }.freeze

public
  def extract(fn)
    @data = {}
    @fh = File.open(fn)
    _extract
    @fh.close
    @data
  end


private
  def _extract
    row = _gets_without_comment
    row = _get_class(row)
    _get_body(row)
  end


  def _get_class(row)
    imports = @data[:imports] = []

    while true
      row, anotations = _get_anotations(row)
      pre, terminate, row = _gets_until(row, /\s*(;|{)/)
      pre.lstrip!

      case terminate
      when ';'
        if m = pre.match(/(package|import)\s+/)
          body = m.post_match.gsub(/\s+/, '')
          case m[1]
          when 'package' then @data[:package] = body
          when 'import'  then imports.push body
          end
        end

      when '{'
        if pre.match(/class/)
          @data[:class] = {
            name: pre.lstrip,
            anotations: anotations,
          }
          return row
        end
        row = _get_bracket(terminate + row, '{')[2]
      end
    end
    raise 'no reach'
  end


  def _get_body(row)
    functions = @data[:functions] = {}
    fields    = @data[:fields]    = {}

    while true
      row, anotations = _get_anotations(row)
      pre, terminate, row = _gets_until(row, /\s*(;|{|})/)
      pre.lstrip!

      case terminate
      when ';' then fields[pre] = anotations
      when '{'
        unless m = pre.match(/class/) # skip internal class
          functions[pre] = anotations
          row = _get_bracket(terminate + row, '{')[2]
        end
      when '}' then break
      end
    end
    row
  end


  def _get_anotations(row)
    anotations = []
    while true
      row, anotation = _get_anotation(row)
      anotation.nil? and break [row, anotations]
      anotations.push anotation
    end
  end


  #
  # get anotation
  # return [row, anotation]
  #
  def _get_anotation(row)
    m = row.match(/\s*@(\w+)\s*(\()?/) or return row
    head, elm = m[1,2]
    elm.empty? and return [m.post, head]
    pre, bracket, post = _get_bracket(elm + m.post_patch, '(')
    [post, head + bracket]
  end


  #
  # get nested bracket
  # return [pre, bracket, post]
  #
  def _get_bracket(row, bracket_s)
    m = row.match(/\s*#{bracket_s}/) or return row

    count = 1
    pbracket = /#{bracket_s}|#{@@BRACKET[bracket_s]}/
    pre = m.pre_match
    row = m.post_match
    buf = [bracket_s]

    while true
      while m = row.match(pbracket)
        buf.push m.pre_match
        buf.push elm = m[0]

        if elm == bracket_s then count += 1
        elsif (count -= 1) <= 0
          return [pre, buf.join, m.post_match]
        end
      end

      buf.push row
      buf.push ' '
      row = _gets_without_comment
    end
    raise 'unreach'
  end


  def _delete_bracket(row, bracket_head)
    buf = []
    while true
      pre, bracket, row = _get_bracket(row, bracket_head)
      buf.push pre
      bracket.nil? and break
    end
    buf.join(' ').strip
  end


  def _delete_line_comment(row)
    (m = row.match(@@LINE_COMMENT)) ? m.pre_match : row
  end


  #
  # return [pre, matching, post]
  #
  def _gets_until(row, c)
    buf = []
    until m = row.match(c)
      buf.push(row = _gets_without_comment)
    end
    [buf.push(m.pre_match).join(' '), m[1], m.post_match]
  end


  def _gets_without_comment
    while true
      row = _gets
      row = _delete_line_comment(row)
      row = _delete_bracket(row, '/\*')
      row = _delete_line_comment(row)
      row.empty? or break row
    end
  end


  def _gets
    row = @fh.gets or raise ReadException

    #
    # Ruby cannot convert from the character code to same one,
    # even if some option is defined.
    # Then, following code cannot work correctly.
    #
    # row.encode!('utf-8',
    #   invalid: :replace,
    #   undef:   :replace,
    #   replace: '?')
    #
    # So, this code uses for previous reason.
    #
    row.force_encoding('UTF-8')
    row.encode!('UTF-8', 'UTF-8')
  end
end

