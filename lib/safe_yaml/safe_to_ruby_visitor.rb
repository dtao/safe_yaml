module SafeYAML
  class SafeToRubyVisitor < Psych::Visitors::ToRuby
    INITIALIZE_ARITY = superclass.method(:initialize).arity

    def initialize(resolver)
      case INITIALIZE_ARITY
      when -1, 0
        super()
      else
        super
      end

      @resolver = resolver
    end

    def accept(node)
      if node.tag
        SafeYAML.tag_safety_check!(node.tag, @resolver.options)
        return super
      end

      @resolver.resolve_node(node)
    end
  end
end
