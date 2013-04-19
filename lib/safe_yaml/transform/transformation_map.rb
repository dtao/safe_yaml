module SafeYAML
  class Transform
    module TransformationMap
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def set_predefined_values(predefined_values)
          expanded_map = predefined_values.inject({}) do |hash, (key, value)|
            hash[key] = value
            hash[key.capitalize] = value
            hash[key.upcase] = value
            hash
          end

          self.const_set(:PREDEFINED_VALUES, expanded_map.freeze)
        end
      end
    end
  end
end
