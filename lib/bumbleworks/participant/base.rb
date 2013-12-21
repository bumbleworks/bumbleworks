module Bumbleworks
  module Participant
    class Base
      include LocalParticipant

      def on_cancel
        # default no-op method
      end
    end
  end
end