module SafeYAML
  class Transform
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

    def self.to_proper_type(value)
      if value.is_a?(String)
        if PREDEFINED_VALUES.include?(value.downcase)
          return PREDEFINED_VALUES[value.downcase]

        elsif value.match(/^:\w+$/)
          return value[1..-1].to_sym

        elsif value.match(/^\d+$/)
          return value.to_i

        elsif value.match(/^\d+(?:\.\d*)?$/) || value.match(/^\.\d+$/)
          return value.to_f
        end
      end

      value
    end
  end
end
