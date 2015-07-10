require 'set'
require 'utils/option'


class ReadCodeBlock
public
  DEFAULT_OPT = {
    terminator: ["\n"],
    comment: { line: '\/\/', block: %w(/\* \*/) },
  }.freeze

  def initialize(opt = {})
    opt = DEFAULT_OPT.merge opt
    terminator = opt[:terminator]
    @is_terminated_by_return = !terminator.delete("\n").nil?
    @_terminator = _get_terminator_func(terminator)

    comment = opt[:comment]
    comment_block = comment[:block]
    @comment = {
      line: /\s*#{comment[:line]}/,
      block: [/\s*#{comment_block[0]}/, /#{comment_block[1]}\s*/],
    }
  end

  def get(fn)
    File.open(fn) { |fh| _get(fh) }
  end


private
  def _get_terminator_func(terminator)
    terminator.empty? and return ->(s){ nil }
    pattern = terminator.join('|')
    ->(s) { s.match(pattern) }
  end


  def _get(fh)
    buffer = []

  end


  def _exec(fh, obj)
    token = []
    buf = ''

    while (true)
      while (buf.empty?)
        buf = _gets_without_comment(fh) or return nil
      end

      if (@is_terminated_by_return)
        token.push buf
        buf = ''
        next
      end

      queue = []
      while (true)
        if m = @_terminator[buf]
          buf = m.post_match

          [queue, m.pre_match].join

          str = [queue, m.pre_match, m[1]].join
          _execute_dispatch(@tail_match, str, obj)

        else
          queue.push buf
          buf = _gets_without_comment(fh) or return nil
        end
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

