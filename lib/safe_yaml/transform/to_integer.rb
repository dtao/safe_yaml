module SafeYAML
  class Transform
    class ToInteger
      MATCHERS = Deep.freeze([
        /\A\s*[-+]?[1-9][0-9_,]*\s*\Z/, # decimal
        /\A\s*0[0-7]+\s*\Z/,           # octal
        /\A\s*0x[0-9a-f]+\s*\Z/i,      # hexadecimal
        /\A\s*0b[01_]+\s*\Z/           # binary
      ])

      def transform?(value)
        MATCHERS.each do |matcher|
          return true, Integer(value.gsub(",", "")) if matcher.match(value)
        end
        try_edge_cases?(value)
      end

      def try_edge_cases?(value)
        return true, Parse::Hexadecimal.value(value) if Parse::Hexadecimal::MATCHER.match(value)
        return true, Parse::Sexagesimal.value(value) if Parse::Sexagesimal::INTEGER_MATCHER.match(value)
        return false
      end
    end
  end
end
