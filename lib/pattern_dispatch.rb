class PatternDispatch
public
  def initialize
    @cases = {}
  end

  def add(pattern, func = nil, &blk)
    @cases[pattern] = blk || func
  end

  def execute(str, data)
    @cases.each do |pattern, func|
      (m = str.match(pattern)) and return func.(m, str, data)
    end
    nil
  end
end

