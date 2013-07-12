require "ruote/part/local_participant"
require "bumbleworks/workitem_entity_storage"

module Bumbleworks
  module LocalParticipant
    include ::Ruote::LocalParticipant
    include WorkitemEntityStorage
  end
end