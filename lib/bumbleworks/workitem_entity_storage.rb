module Bumbleworks
  module WorkitemEntityStorage
    class EntityNotFound < StandardError; end

    def entity(options = {})
      @entity = nil if options[:reload] == true
      @entity ||= if has_entity_fields?
        klass = Bumbleworks::Support.constantize(entity_type)
        entity = klass.first_by_identifier(entity_id)
      end
      raise EntityNotFound unless @entity
      @entity
    end

    def has_entity?
      !entity.nil?
    rescue EntityNotFound
      false
    end

    def has_entity_fields?
      entity_id && entity_type
    end

    def entity_fields(options = {})
      return {} unless has_entity_fields?
      type = if options[:humanize] == true
        Bumbleworks::Support.humanize(entity_type)
      elsif options[:titleize] == true
        Bumbleworks::Support.titleize(entity_type)
      else
        entity_type
      end
      {
        :type => type,
        :identifier => entity_id
      }
    end

  private

    def entity_id
      workitem.fields[:entity_id] || workitem.fields['entity_id']
    end

    def entity_type
      workitem.fields[:entity_type] || workitem.fields['entity_type']
    end
  end
end