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

    TRANSFORMABLE_PREFIXES = Set.new("-+0123456789.~OoYyNnTtFf:".chars)

    def self.to_guessed_type(value, quoted=false, options=nil)
      return value if quoted

      if value.is_a?(String) && (value.empty? || TRANSFORMABLE_PREFIXES.include?(first_non_empty_char(value)))
        TRANSFORMERS.each do |transformer|
          success, transformed_value = transformer.method(:transform?).arity == 1 ?
            transformer.transform?(value) :
            transformer.transform?(value, options)

          return transformed_value if success
        end
      end

      value
    end

    def self.to_proper_type(value, quoted=false, tag=nil, options=nil)
      case tag
      when "tag:yaml.org,2002:binary", "x-private:binary", "!binary"
        decoded = Base64.decode64(value)
        decoded = decoded.force_encoding(value.encoding) if decoded.respond_to?(:force_encoding)
        decoded
      else
        self.to_guessed_type(value, quoted, options)
      end
    end

    private

    def self.first_non_empty_char(string)
      string.each_char do |char|
        return char if char != " "
      end

      nil
    end
  end
end
