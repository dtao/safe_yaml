module SafeYAML
  class Transform
    DEFAULT_OPTIONS = {
      :enable_symbol_parsing => false
    }

    PREDEFINED_VALUES = {
      ""      => nil,
      "~"     => nil,
      "null"  => nil,
      "yes"   => true,
      "on"    => true,
      "true"  => true,
      "no"    => false,
      "off"   => false,
      "false" => false
    }.freeze

    SYMBOL_MATCHER = /^:\w+$/.freeze

    INTEGER_MATCHER = /^\d+$/.freeze

    FLOAT_MATCHER = /^(?:\d+(?:\.\d*)?$)|(?:^\.\d+$)/.freeze

    def self.to_proper_type(value, options={})
      enable_symbol_parsing = options[:enable_symbol_parsing] || DEFAULT_OPTIONS[:enable_symbol_parsing]

      if value.is_a?(String)
        if PREDEFINED_VALUES.include?(value.downcase)
          return PREDEFINED_VALUES[value.downcase]

        elsif DEFAULT_OPTIONS[:enable_symbol_parsing] && value.match(SYMBOL_MATCHER)
          return value[1..-1].to_sym

        elsif value.match(INTEGER_MATCHER)
          return value.to_i

        elsif value.match(FLOAT_MATCHER)
          return value.to_f
        end
      end

      value
    end
  end
end
