module Bumbleworks
  module WorkitemEntityStorage
    extend Forwardable

    delegate [:entity, :has_entity?, :has_entity_fields?, :entity_fields, :entity_name] => :entity_storage_workitem

    def entity_storage_workitem(the_workitem = workitem)
      @entity_storage_workitem ||= wrapped_workitem(the_workitem)
    end

    def wrapped_workitem(the_workitem)
      if the_workitem.is_a? Bumbleworks::Workitem
        the_workitem
      else
        Bumbleworks::Workitem.new(the_workitem)
      end
    end
  end
end