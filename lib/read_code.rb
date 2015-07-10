require 'set'


class ReadCode
public
  #
  # open file and read token via get function
  #
  def open(fn, &blk)
    File.open(fn) do |fh|
      blk.(@file_handler.new(fh, @terminate_pattern))
    end
  end


public
  def initialize(opt = {})
    @terminate_pattern = _get_terminate_pattern(opt[:terminates])

    #
    # file handler for ReadCode
    # cannot create object from outer
    #
    @file_handler = Class.new do
    public
      def initialize(fh, terminate_pattern)
        @terminate_pattern = terminate_pattern
        @fh  = fh
        @buf = ''
      end

      #
      # get token
      # which removed comments (//, /**/)
      # and until \n or terminated char (pattern)
      #
      def get
        while @buf.empty?
          @buf = _get or return nil
        end

        if (m = @buf.match(@terminate_pattern))
          @buf = m.post_match
          return "#{m.pre_match}#{m[1]}"
        end

        ret = @buf
        @buf = ''
        ret
      end


    private
      def _gets
        row = @fh.gets or return nil

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


      def _get
        row = _gets or return nil
        (m = row.match(/\s*\/\//)) and return m.pre_match
        row.lstrip!

        row.chomp!
        (m = row.match(/\s*\/\*/)) or return row.rstrip
        former = m.pre_match

        row = m.post_match
        until (m = row.match(/\*\/\s*/))
          row = _gets or return nil
        end

        latter = m.post_match.chomp.rstrip
        former.empty? and return latter
        latter.empty? or former += " #{latter}"
        former
      end
    end
  end


private
  def _get_terminate_pattern(terminates)
    ret = Set.new
    ret.add ';' # for default terminate character

    case terminates
    when NilClass then # nop
    when String   then terminates.empty? or ret.add terminates
    when Array    then terminates.each { |i| ret.add i }
    else raise 'not Array of terminates'
    end
    /(#{ret.to_a.join('|')})/
  end
end

