require 'zlib'
require 'yaml'
require 'utils/file_opener'


module Utils
module YamlHelper
  class << self
  public
    def read(fn)
      File.exist?(fn) or raise "not exist: #{fn}"
      case File.extname(fn)
      when '.gz' then _read_gz(fn)
      else YAML.load_file(fn)
      end

    rescue => e
      STDERR.puts "yaml format error: #{fn}"
      raise e
    end


    def write(data, fn = nil)
      case fn
      when String
        Utils::FileOpener.open(fn, :w) { |f| _write(data, f) }
      when NilClass then _write(data, STDOUT)
      when IO       then _write(data, fn)
      end
    end


  private
    def _read_gz(fn)
      Zlib::GzipReader.open(fn) { |f| YAML.load(f.read) }
    end


    def _write(info, f, indent = '')
      info.each do |k, v|
        case v
        when Symbol then _write_for_s(k, v.to_s, f, indent)
        when String then _write_for_s(k, v, f, indent)
        when Array  then _write_for_a(k, v, f, indent)
        when Hash
          f.puts "#{indent}#{k}:"
          _write(v, f, indent + '  ')

        else
          c = v.class
          if c.method_defined?(:to_a)
            _write_for_a(k, v.to_a, f, indent)
          else raise "no output for #{c}: #{v}"
          end
        end
      end
    end


    def _escape(s)
      s.match('"') ? %Q("#{s.gsub('"', '\\\\"')}") : s
    end

    def _write_for_s(k, s, f, indent)
      f.puts "#{indent}#{k}: #{_escape(s)}"
    end

    def _write_for_a(k, a, f, indent)
      f.puts "#{indent}#{k}:"
      a.compact.each { |i| f.puts "#{indent}- #{_escape(i)}" }
    end
  end
end
end

