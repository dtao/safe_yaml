require 'base64'

module SafeYAML
  class Transform
    TRANSFORMERS = [
      Transform::ToSymbol.new,
      Transform::ToInteger.new,
      Transform::ToFloat.new,
      Transform::ToNil.new,
      Transform::ToBoolean.new,
      Transform::ToDate.new
    ]

    def self.to_guessed_type(value, quoted=false)
      return value if quoted

      if value.is_a?(String)
        TRANSFORMERS.each do |transformer|
          success, transformed_value = transformer.transform?(value)
          return transformed_value if success
        end
      end

      value
    end

    def self.to_proper_type(value, quoted=false, tag=nil)
      case tag
      when "tag:yaml.org,2002:binary", "x-private:binary", "!binary"
        decoded = Base64.decode64(value)
        decoded = decoded.force_encoding(value.encoding) if decoded.respond_to?(:force_encoding)
        decoded
      else
        self.to_guessed_type(value, quoted)
      end
    end
  end
end
