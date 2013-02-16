module SafeYAML
  class Transform
    class ToSymbol
      MATCHER = /\A:\w+\Z/.freeze

      def transform?(value)
        return false unless SafeYAML::OPTIONS[:deserialize_symbols] && MATCHER.match(value)
        return true, value[1..-1].to_sym
      end
    end
  end
end
