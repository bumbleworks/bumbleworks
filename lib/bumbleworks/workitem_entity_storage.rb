module Bumbleworks
  module WorkitemEntityStorage
    extend Forwardable

    delegate [:entity, :has_entity?, :has_entity_fields?, :entity_fields] => :entity_storage_workitem

    def entity_storage_workitem
      @entity_storage_workitem ||= Bumbleworks::Workitem.new(workitem)
    end
  end
end