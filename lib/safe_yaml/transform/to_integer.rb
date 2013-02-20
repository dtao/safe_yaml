module SafeYAML
  class Transform
    class ToInteger
      def transform?(value)
        return true, Integer(value) rescue false
      end
    end
  end
end
