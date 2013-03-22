module SafeYAML
  class SafeToRubyVisitor < Psych::Visitors::ToRuby
    def initialize(resolver)
      super()
      @resolver = resolver
    end

    def accept(node)
      if node.tag
        return super if @resolver.tag_is_whitelisted?(node.tag)
        raise "Unknown YAML tag '#{node.tag}'" if @resolver.options[:raise_on_unknown_tag]
      end

      @resolver.resolve_node(node)
    end
  end
end
