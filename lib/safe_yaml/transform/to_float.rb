module SafeYAML
  class Transform
    class ToFloat
      Infinity = 1.0 / 0.0
      NaN = 0.0 / 0.0

      PREDEFINED_VALUES = {
        ".inf"  => Infinity,
        ".Inf"  => Infinity,
        ".INF"  => Infinity,
        "-.inf" => -Infinity,
        "-.Inf" => -Infinity,
        "-.INF" => -Infinity,
        ".nan"  => NaN,
        ".NaN"  => NaN,
        ".NAN"  => NaN,
      }.freeze

      SEXAGESIMAL_MATCHER = /\A[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*\Z/.freeze

      def transform?(value)
        return true, Float(value) rescue try_edge_cases?(value)
      end

      def try_edge_cases?(value)
        return true, PREDEFINED_VALUES[value] if PREDEFINED_VALUES.include?(value)
        return true, parse_sexagesimal(value) if SEXAGESIMAL_MATCHER.match(value)
        return false
      end

      def parse_sexagesimal(value)
        before_decimal, after_decimal = value.split(".")

        whole_part = 0
        multiplier = 1

        before_decimal = before_decimal.split(":")
        until before_decimal.empty?
          whole_part += (Float(before_decimal.pop) * multiplier)
          multiplier *= 60
        end

        result = whole_part + Float("." + after_decimal)
        result *= -1 if value[0] == "-"
        result
      end
    end
  end
end
