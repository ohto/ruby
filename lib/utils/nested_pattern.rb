module Utils
  module NestedPattern
    KLASS = /
      (?<klass>
        (?<klass_part>([A-Z]\w*|\?)
          (\s*<\s*\g<klass_part>(\s+extends\s+\g<klass_part>)?
          (\s*,\s*\g<klass_part>(\s+extends\s+\g<klass_part>)?)*\s*>)?)
      )/x

    KLASS_LINE = /
      ((?<access>public|protected|private)\s)?\s*
      ((abstract|final)\s+)?
      (?<type>class|@?interface|enum)\s+
      #{KLASS}
      (\s+(?<option>.*?))?
      \s*{/x

    FUNC_HEAD = /
      (?<access>public)\s+(static\s+)?
        (?<all>
        (<[^>]+>\s+)?((?<ret>\w+)(\s*<.+>)?\s+)?
        (?<name>\w+)\s*
        \(\s*(?<params>.*?)\s*\)
      \s*?(throws\s+[^()]+?)?
      )\s*/x

    FUNC_LINE = /#{FUNC_HEAD}{/
  end
end

