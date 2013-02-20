module SafeYAML
  class Transform
    class ToInteger
      OCTAL_MATCHER = /\A0[0-7]+\Z/.freeze
      HEXADECIMAL_MATCHER = /\A0x[0-9a-f]+\Z/i.freeze
      MATCHER = /\A[1-9]\d*\Z/.freeze

      def transform?(value)
        if OCTAL_MATCHER.match(value) || HEXADECIMAL_MATCHER.match(value)
          return true, Integer(value)
        end

        return false unless MATCHER.match(value)
        return true, value.to_i
      end
    end
  end
end
