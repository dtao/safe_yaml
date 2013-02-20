module SafeYAML
  class Transform
    class ToInteger
      def transform?(value)
        return true, Integer(value) rescue try_edge_cases?(value)
      end

      def try_edge_cases?(value)
        return true, Parse::Hexadecimal.value(value) if Parse::Hexadecimal::MATCHER.match(value)
        return true, Parse::Sexagesimal.value(value) if Parse::Sexagesimal::INTEGER_MATCHER.match(value)
        return false
      end
    end
  end
end
