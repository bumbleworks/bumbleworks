module Bumbleworks
  module Support
    module FlowExpression
      def tag_from_attribute
        tag = attribute_text.to_s
        if h.updated_tree[1]['for_entity'].to_s == 'true'
          workitem_fields = h.applied_workitem['fields']
          entity_type, entity_id = workitem_fields.values_at('entity_type', 'entity_id')
          if entity_type && entity_id
            entity_tag = "#{Bumbleworks::Support.tokenize(entity_type)}_#{entity_id}"
            tag += "__for_entity__#{entity_tag}"
          end
        end
        tag
      end
    end
  end
end