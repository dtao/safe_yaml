module SafeYAML
  class Transform
    class ToInteger
      MATCHERS = [
        /\A[-+]?[1-9][0-9_]*\Z/.freeze, # decimal
        /\A0[0-7]+\Z/.freeze,           # octal
        /\A0x[0-9a-f]+\Z/i.freeze,      # hexadecimal
        /\A0b[01_]+\Z/.freeze           # binary
      ].freeze

      def transform?(value)
        MATCHERS.each do |matcher|
          return true, Integer(value) if matcher.match(value)
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
