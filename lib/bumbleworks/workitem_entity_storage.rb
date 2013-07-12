module Bumbleworks
  module WorkitemEntityStorage
    class EntityNotFound < StandardError; end

    def entity
      if has_entity_fields?
        klass = Bumbleworks::Support.constantize(workitem.fields['entity_type'])
        entity = klass.first_by_identifier(workitem.fields['entity_id'])
      end
      raise EntityNotFound unless entity
      entity
    end

    def has_entity?
      !entity.nil?
    rescue EntityNotFound
      false
    end

    def has_entity_fields?
      workitem.fields['entity_id'] && workitem.fields['entity_type']
    end
  end
end