module Bumbleworks
  module Participant
    class StorageParticipant < ::Ruote::StorageParticipant
      def on_workitem
        return_value = super
        Bumbleworks::Task.new(self[workitem.sid]).on_dispatch
        return return_value
      end
    end
  end
end