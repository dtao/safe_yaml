module SafeYAML
  class PsychVisitor < Psych::Visitors::ToRuby
    def initialize(resolver)
      super
      @resolver = resolver
    end

    def accept(node)
      return super if @resolver.tag_is_whitelisted?(@resolver.get_node_tag(node))
      @resolver.resolve_node(node)
    end
  end
end
