module SafeYAML
  class SyckResolver
    def resolve_node(node)
      case node.kind
      when :map
        return resolve_map(node.value)
      when :seq
        return resolve_seq(node.value)
      when :scalar
        return resolve_scalar(node.value)
      else
        raise "Don't know how to resolve a '#{node.kind}' node!"
      end
    end

    def resolve_map(map)
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

    def resolve_seq(seq)
      seq.map { |node| resolve_node(node) }
    end

    def resolve_scalar(scalar)
      Transform.to_proper_type(scalar)
    end
  end
end
