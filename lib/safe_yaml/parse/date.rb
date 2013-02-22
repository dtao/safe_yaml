module SafeYAML
  class Parse
    class Date
      DATE_MATCHER = /\A(\d{4})-(\d{2})-(\d{2})\Z/.freeze
      TIME_MATCHER = /\A\d{4}-\d{1,2}-\d{1,2}(?:[Tt]|\s+)\d{1,2}:\d{2}:\d{2}(?:\.\d*)?\s*(?:Z|[-+]\d{1,2}(?::?\d{2})?)?\Z/.freeze

      SECONDS_PER_DAY = 60 * 60 * 24

      def self.value(value)
        d = DateTime.parse(value)
        usec = d.sec_fraction * SECONDS_PER_DAY * 1000000.0
        Time.utc(d.year, d.month, d.day, d.hour, d.min, d.sec, usec) - (d.offset * SECONDS_PER_DAY)
      end
    end
  end
end
