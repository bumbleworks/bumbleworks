require "bumbleworks/local_participant"

module Bumbleworks
  class Participant
    include LocalParticipant

    def on_cancel
      # default no-op method
    end
  end
end