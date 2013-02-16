module SafeYAML
  class PsychResolver < Resolver
    NODE_TYPES = {
      Psych::Nodes::Document => :seq,
      Psych::Nodes::Mapping  => :map,
      Psych::Nodes::Sequence => :seq,
      Psych::Nodes::Scalar   => :scalar,
      Psych::Nodes::Alias    => :alias
    }.freeze

    def initialize
      super
      @aliased_nodes = {}
    end

    def resolve_tree(tree)
      resolve_node(tree)[0]
    end

    def resolve_alias(node)
      resolve_node(@aliased_nodes[node.anchor])
    end

    def get_node_type(node)
      NODE_TYPES[node.class]
    end

    def get_node_tag(node)
      node.tag
    end

    def get_node_value(node)
      case get_node_type(node)
      when :map
        @aliased_nodes[node.anchor] = node if node.anchor
        node.children
      when :seq
        node.children
      when :scalar
        node.value
      end
    end

    def value_is_quoted?(node)
      node.quoted
    end
  end
end
