module SafeYAML
  class SyckResolver
    QUOTE_STYLES = [:quote1, :quote2]

    def resolve_node(node)
      case node.kind
      when :map
        return resolve_map(node)
      when :seq
        return resolve_seq(node)
      when :scalar
        return resolve_scalar(node)
      else
        raise "Don't know how to resolve a '#{node.kind}' node!"
      end
    end

    def resolve_map(node)
      map = node.value

      hash = {}
      map.each do |key_node, value_node|
        if resolve_node(key_node) == "<<"
          hash.merge!(resolve_node(value_node))
        else
          hash[resolve_node(key_node)] = resolve_node(value_node)
        end
      end

      return hash
    end

    def resolve_seq(node)
      seq = node.value

      seq.map { |node| resolve_node(node) }
    end

    def resolve_scalar(node)
      Transform.to_proper_type(node.value, QUOTE_STYLES.include?(node.instance_variable_get(:@style)))
    end
  end
end
