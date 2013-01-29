module SafeYAML
  class Transform
    class ToDate
      MATCHER = /^\d{4}\-\d{2}\-\d{2}$/.freeze

      def transform?(value)
        return false unless MATCHER.match(value)
        date = Date.parse(value) rescue nil
        return !!date, date
      end
    end
  end
end
