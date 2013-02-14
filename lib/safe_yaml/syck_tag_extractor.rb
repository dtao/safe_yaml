module SafeYAML
  class SyckTagExtractor
    QUOTE_STYLES = [:quote1, :quote2]

    attr_reader :tags

    def initialize
      @tags = Set.new
    end

    def extract(node)
      return unless node.respond_to?(:type_id)
      if !QUOTE_STYLES.include?(node.instance_variable_get(:@style)) && node.value.is_a?(String)
        YAML.check_string_for_symbol!(node.value)
      end
      @tags << node.type_id if node.type_id

      case node.value
      when Hash
        node.value.each { |k,v| extract(k); extract(v) }
      when Array
        node.value.each { |i| extract(i) }
      end
    end
  end
end
