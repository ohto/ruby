module Utils
  def self.load_child_module
    dn = File.dirname(File.expand_path(__FILE__))
    cn = File.join(dn, File.basename(__FILE__, '.rb'))
    Dir.foreach(cn) do |fn|
      fn.match(/^[^.].+\.rb$/) or next
      require File.join(cn, File.basename(fn, '.rb'))
    end
  end
end

Utils.load_child_module

