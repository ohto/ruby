require 'utils'


class FileTraverse
public
  def initialize(opt = {})
    @_ext       = _init(opt[:ext], '\.')
    @_exclusive = _init(opt[:exclusive])
  end

  def traverse(base, &blk)
    (@blk = blk).nil? and raise 'no block'
    fn = File.expand_path(base)
    File.exist?(fn) or raise "no exist: #{base}"
    _traverse(fn)
  end


private
  def _traverse(dn)
    (fn = File.basename(dn)).match(/^\./) and return
    if File.file?(dn) 
      @_ext.(File.extname(fn)) and @blk.(dn)
    else
      unless @_exclusive.(fn)
        Dir.foreach(dn) { |cfn| _traverse(File.join(dn, cfn)) }
      end
    end
  end

  def _init(opt, add_for = '')
    opt.nil? and return ->(fn) { false }
    pattern = "#{add_for}#{Utils::Option.to_array(opt).join('|')}"
    ->(fn) { fn.match(pattern) }
  end
end

