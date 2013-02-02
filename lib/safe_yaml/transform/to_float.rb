module SafeYAML
  class Transform
    class ToFloat
      MATCHER = /\A(?:\d+(?:\.\d*)?\Z)|(?:^\.\d+\Z)/.freeze

      def transform?(value)
        return false unless MATCHER.match(value)
        return true, value.to_f
      end
    end
  end
end
