module SafeYAML
  class PsychTagExtractor < Psych::Handler
    attr_reader :tags

    def initialize
      @tags = Set.new
    end

    def streaming?
      false
    end

    def alias(anchor)
    end

    def scalar(value, anchor, tag, plain, quoted, style)
      if !quoted && value.is_a?(String)
        YAML.check_string_for_symbol!(value)
      end
      @tags << tag if tag
    end

    def start_mapping(anchor, tag, implicit, style)
      @tags << tag if tag
    end

    def end_mapping
    end

    def start_sequence(anchor, tag, implicit, style)
      @tags << tag if tag
    end

    def end_sequence
    end
  end
end
