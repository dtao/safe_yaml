module SafeYAML
  class Transform
    TRANSFORMERS = [
      Transform::ToSymbol.new,
      Transform::ToInteger.new,
      Transform::ToFloat.new,
      Transform::ToNil.new,
      Transform::ToBoolean.new,
      Transform::ToDate.new,
      Transform::ToTime.new
    ]

    def self.to_proper_type(value)
      if value.is_a?(String)
        TRANSFORMERS.each do |transformer|
          success, transformed_value = transformer.transform?(value)
          return transformed_value if success
        end
      end

      value
    end
  end
end
