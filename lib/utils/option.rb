module Utils
module Option
  class << self
  public
    def get_func(func, blk)
      blk.nil?  and return func.nil? ? nil : func
      func.nil? and return blk
      raise "anbiguous opener: #{func}, #{blk}"
    end


    def to_array(opt)
      for_s = ->(s) { s.empty? ? [] : [s] }
      for_a = ->(a) do
        a.flatten.uniq.map { |d|
          (d = d.to_s).empty? ? nil : d
        }.compact
      end

      case opt
      when Array    then _to_array_for_a(opt)
      when String   then _to_array_for_s(opt)
      when Symbol   then _to_array_for_s(opt.to_s)
      when NilClass then []
      else
        c = opt.class
        if c.method_defined?(:to_a)
          _to_array_for_a(opt.to_a)
        else raise "not suitable option #{c}: #{opt}"
        end
      end
    end


  private
    def _to_array_for_s(s)
      s.empty? ? [] : [s]
    end

    def _to_array_for_a(a)
      a.flatten.uniq.map { |d| (d = d.to_s).empty? ? nil : d }.compact
    end
  end
end
end

