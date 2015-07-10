require 'set'
require 'utils/option'


class ReadCodeJava
public
  DEFAULT_OPT = {
    terminator: %w(;),
    comment: {
      line: '\/\/',
      block: %w(/\* \*/),
    },
  }.freeze


  def initialize(opt = {})
    opt = DEFAULT_OPT.merge opt
    terminator = Set.new
    Utils::Option.to_array(opt[:terminator]).each { |d| terminator.add d }
    terminator.empty? and raise 'terminator sould be defined'
    @terminal_pattern = /(#{terminator.to_a.join('|')})/

    comment = opt[:comment]
    comment_block = comment[:block]
    @comment = {
      line: /\s*#{comment[:line]}/,
      block: [/\s*#{comment_block[0]}/, /#{comment_block[1]}\s*/],
    }

    @head_match = {}
    @tail_match = {}
  end

  def add_callback_head(pattern, opt = {}, &blk)
    func = Utils::Option.get_func(opt[:func], blk) or return false
    @head_match[/\s*#{pattern}/] = func
    true
  end

  def add_callback_tail(pattern, opt = {}, &blk)
    func = Utils::Option.get_func(opt[:func], blk) or return false
    @tail_match[pattern] = func
    true
  end

  def exec(fn, obj = nil)
    File.open(fn) { |fh| _exec(fh, obj) }
  end


private
  def _execute_dispatch(dispatcher, str, obj)
    dispatcher.each do |pattern, func|
      (m = str.match(pattern)) or next
      return func.(m, obj)
    end
    false
  end


  #
  # get token
  #
  def _exec(fh, obj)
    buf = ''
    queue = []

    while (true)
      while (buf.empty?)
        buf = _gets_without_comment(fh) or return nil
      end

      if _execute_dispatch(@head_match, buf, obj)
        buf.clear
        next
      end

      queue.clear
      while (true)
        if m = buf.match(@terminal_pattern)
          buf = m.post_match
          str = [queue, m.pre_match, m[1]].join
          _execute_dispatch(@tail_match, str, obj)
          break
        end
        queue.push buf
        buf = _gets_without_comment(fh) or return nil
      end
    end
  end


  #
  # get string terminated '\n'
  # and removed comments (//, /**/)
  #
  def _gets_without_comment(fh)
    row = _gets(fh) or return nil
    (m = row.match(@comment[:line])) and return m.pre_match.lstrip

    row.lstrip.chomp!
    cblock_pre, cblock_post = @comment[:block]
    (m = row.match(cblock_pre)) or return row.rstrip

    former = m.pre_match.lstrip
    row    = m.post_match
    until (m = row.match(cblock_post))
      row = _gets(fh) or return nil
    end

    latter = m.post_match.chomp.rstrip
    former.empty? and return latter
    latter.empty? or former += " #{latter}"
    former
  end


  def _gets(fh)
    row = fh.gets or return nil

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

