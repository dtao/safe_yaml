require "yaml"

module SafeYAML
  class Handler < Psych::Handler
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

    def initialize
      @anchors = {}
      @stack = []
    end

    def result
      @result
    end

    def add_to_current_structure(value, anchor=nil)
      value = transform_value(value)

      @anchors[anchor] = value if anchor

      if @result.nil?
        @result = value
        @current_structure = @result
        return
      end

      case @current_structure
      when Array
        @current_structure.push(value)

      when Hash
        if @current_key.nil?
          @current_key = value

        else
          if @current_key == "<<"
            @current_structure.merge!(value)
          else
            @current_structure[@current_key] = value
          end

          @current_key = nil
        end

      else
        raise "Don't know how to add to a #{@current_structure.class}!"
      end
    end

    def transform_value(value)
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

    def end_current_structure
      @stack.pop
      @current_structure = @stack.last
    end

    def streaming?
      false
    end

    # event handlers
    def alias(anchor)
      add_to_current_structure(@anchors[anchor])
    end

    def scalar(value, anchor, tag, plain, quoted, style)
      add_to_current_structure(value, anchor)
    end

    def start_mapping(anchor, tag, implicit, style)
      map = {}
      self.add_to_current_structure(map, anchor)
      @current_structure = map
      @stack.push(map)
    end

    def end_mapping
      self.end_current_structure()
    end

    def start_sequence(anchor, tag, implicit, style)
      seq = []
      self.add_to_current_structure(seq, anchor)
      @current_structure = seq
      @stack.push(seq)
    end

    def end_sequence
      self.end_current_structure()
    end
  end
end
