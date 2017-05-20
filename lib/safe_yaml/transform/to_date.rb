module SafeYAML
  class Transform
    class ToDate
      def transform?(value, options=SafeYAML::OPTIONS)
        return true, Date.parse(value) if Parse::Date::DATE_MATCHER.match(value)
        return true, Parse::Date.value(value, options[:preserve_timezone]) if Parse::Date::TIME_MATCHER.match(value)
        false
      rescue ArgumentError
        return true, value
      end
    end
  end
end
