require "psych"

module SafeYAML
  class Handler < Psych::Handler
    def initialize
      @stack = []
    end

    def result
      @result
    end

    def add_to_current_structure(value)
      if @result.nil?
        @result = value
        @current_structure = @result
        return
      end

      case @current_structure
      when Array
        @current_structure.push(transform_value(value))

      when Hash
        if @current_key.nil?
          @current_key = transform_value(value)
        else
          @current_structure[@current_key] = transform_value(value)
          @current_key = nil
        end

      else
        raise "Don't know how to add to a #{@current_structure.class}!"
      end
    end

    def transform_value(value)
      if value.is_a?(String)
        if value.match(/^:\w+$/)
          return value[1..-1].to_sym

        elsif value.match(/^\d+$/)
          return value.to_i

        elsif value.match(/^\d+(?:\.\d*)?$/) || value.match(/^\.\d+$/)
          return value.to_f
        end
      end

      value
    end

    def streaming?
      false
    end

    # event handlers
    def scalar(value, anchor, tag, plain, quoted, style)
      add_to_current_structure(value)
    end

    def start_mapping(*args) # anchor, tag, implicit, style
      map = {}
      self.add_to_current_structure(map)
      @current_structure = map
      @stack.push(map)
    end

    def end_mapping
      @stack.pop
      @current_structure = @stack.last
    end

    def start_sequence(*args) # anchor, tag, implicit, style
      seq = []
      self.add_to_current_structure(seq)
      @current_structure = seq
      @stack.push(seq)
    end

    def end_sequence
      @stack.pop
      @current_structure = @stack.last
    end
  end
end
