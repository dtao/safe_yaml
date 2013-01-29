module SafeYAML
  class Transform
    class ToSymbol
      MATCHER = /^:\w+$/.freeze

      def transform?(value)
        return false if !Transform::OPTIONS[:enable_symbol_parsing] || !MATCHER.match(value)
        return true, value[1..-1].to_sym
      end
    end
  end
end
