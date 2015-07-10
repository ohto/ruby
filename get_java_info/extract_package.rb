require 'set'
require 'yaml'
require 'optparse'
require 'pp'


class ExtractPackage
public
  def extract(opt)
    ifn = opt[:input]  or return
    ofn = opt[:output] or raise 'output file is required'

    print_func = {
      '.yaml' => :_print_yaml,
      '.dot'  => :_print_dot,
    }[ext = File.extname(ofn)]
    print_func or raise "unknown out format #{ext}"

    odata = _extract(_load_yaml(ifn), opt)
    File.open(ofn, 'w') { |f| send(print_func, odata, f, opt) }
  end


private
  def _load_yaml(fn)
    File.exist?(fn) or raise "not exist: #{fn}"
    YAML.load_file(fn) rescue raise "yaml format error: #{fn}"
  end

  def _get_target_match(opt)
    target = opt[:target_package]
    opt[:with_match] ? ->(i) { i.match(target) } : ->(i) { i == target }
  end


  def _extract(data, opt)
    odata    = {}
    packages = []
    _target_match = _get_target_match(opt)

    data.each do |package, pkg_info|
      project = pkg_info.delete('source').match(/^([^\/]+)\//)[1]
      _target_match[project] or next

      packages.push package
      dt = (odata[project] ||= {})[package] = Set.new
      pkg_info.each do |klass, klass_info|
        (import = klass_info['import']) or next
        import.each { |i| dt.add i.match(/\.[^.]+$/).pre_match }
      end
    end

    odata.each do |_, project_info|
      project_info.each do |_, import|
        import.keep_if { |i| packages.include?(i) }
      end
    end
    odata
  end


  def _print_yaml(odata, f_out, opt = {})
    odata.each do |project, project_info|
      f_out.puts "#{project}:"
      project_info.each do |package, import|
        f_out.puts "  #{package}:"
        import.each { |i| f_out.puts "  - #{i}" }
        f_out.puts
      end
    end
  end


  def _subgroup(package, n)
    m = package.split('.')
    (n <= m.size) ? m[0,n].join('.') : nil
  end

  def _get_subgroup(project_info, n)
    dt = {}
    other = []
    ((n = n.to_i) < 1) and n = 1

    project_info.each_key do |package|
      if s = _subgroup(package, n) then (dt[s] ||= []).push package
      else other.push package
      end
    end

    dt.delete_if do |_, v|
      (v.size <= 1) and v.each { |i| other.push i }
    end
    [dt, other]
  end


  def _get_color(odata, range)
    count = Hash.new(0)
    odata.each do |project, project_info|
      project_info.each do |package, import|
        import.each { |i| count[i] += 1 }
      end
    end
    count.empty? and return count

    if    (0.5 < range) then range = 0.5
    elsif (range < 0.1) then range = 0.1
    end

    sorted = count.sort { |(_, v1), (_, v2)| v1 <=> v2 }
    size   = count.size

    lower = (size *      range ).to_i
    upper = (size * (1 - range)).to_i

    color = {}
    (0    ..(lower - 1)).each { |i| color[sorted[i][0]] = '#9999FF' }
    (upper..(size  - 1)).each { |i| color[sorted[i][0]] = '#FF9999' }
    color
  end


  def _print_dot(odata, f_out, opt = {})
    subgroup_level = opt[:subgroup_level] || 2
    color = _get_color(odata, opt[:range] || 0.1)

    style = {}
    f_out.puts "digraph #{File.basename(__FILE__, '.rb')} {"
    f_out.puts '  graph [rankdir=RL]'

    odata.each do |project, project_info|
      f_out.puts %Q(  subgraph "cluster_#{project}" {)
      f_out.puts %Q(    label = "#{project}")

      dt, other = _get_subgroup(project_info, subgroup_level)
      dt.each do |sub, packages|
        f_out.puts %Q(    subgraph "cluster_#{sub}" {)
        f_out.puts %Q(      label = "#{sub}")
        packages.each do |i|

          style.clear
          if c = color[i]
            style[:style] = :filled
            style[:fillcolor] = c
          end

          if s = _subgroup(i, subgroup_level + 1)
            style[:group] = s
          end

          fmt = if style.empty? then ''
          else
            s = style.map { |k, v| %Q(#{k} = "#{v}") }
            %Q( [#{s.join(' ,')}])
          end
          f_out.puts %Q(      "#{i}"#{fmt})

        end
        f_out.puts '    }'
      end
      other.each { |i| f_out.puts %Q(    "#{i}") }
      f_out.puts '  }'
    end

    odata.each do |project, project_info|
      project_info.each do |package, import|
        import.each do |i|
          (i == package) or f_out.puts %Q(  "#{package}" -> "#{i}")
        end
      end
    end
    f_out.puts '}'
  end

end


opts = {
  input:          'class.info.yaml',
#  target_package: 'company-spreadsheet',
  subgroup_level:  2,
  range:           0.1,
}

OptionParser.new do |opt|
  opt.on('-i','--input=VALUE', 'class.info.yaml') do |v|
    opts[:input] = v
  end

  opt.on('-o','--output=VALUE', '.yaml or .dot') do|v|
    opts[:output] = v
  end

  opt.on('-t','--target_package=VALUE',
         'string which include package name') do |v|
    opts[:target_package] = v
  end

  opt.on('-m','--with_match',
         'target package is included string <target_package>') do |v|
    opts[:with_match] = v
  end

  opt.on('-s','--subgroup_level=VALUE', 'larger than 1') do |v|
    opts[:subgroup_level ] = v.to_i
  end

  opt.on('-r','--range=VALUE',
         'colored range from 0.1 to 0.5') do |v|
    opts[:range] = v.to_f
  end

  opt.parse!(ARGV)
end

pp opts
ExtractPackage.new.extract(opts)

