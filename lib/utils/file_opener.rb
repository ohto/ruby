require 'zlib'
require 'utils/option'


module Utils
module FileOpener
  class << self
  public
    def open(fn, mode = 'r', &blk)
      defined?(@@opener) or _init
      if opener = @@opener[File.extname(fn).to_sym]
        opener.(fn, mode, blk)
      else File.open(fn, mode.to_s) { |f| blk.(f) }
      end
    end

    def add(ext, func = nil, &blk)
      defined?(@@opener) or _init
      func = Utils::Option.get_func(func, blk) or return
      @@opener[ext.to_sym] = func
    end

    def del(ext)
      defined?(@@opener) or _init
      @@opener.delete(ext.to_sym)
    end


  private
    def _init
      @@opener = {}
      _init_gz
    end

    def _init_gz
      add('.gz') do |fn, mode, blk|
        opener = case mode.to_sym
        when :r then Zlib::GzipReader
        when :w then Zlib::GzipWriter
        else raise 'not supported for .gz'
        end
        opener.open(fn) { |f| blk[f] }
      end
    end
  end
end
end

