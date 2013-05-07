module Bumbleworks
  module Helpers
    module Participant
      # managing participants
      def register_participant_list
        if @participant_block.is_a? Proc
          dashboard.register &@participant_block
        end

        unless dashboard.participant_list.any? {|pl| pl.regex == "^.+$"}
          catchall = ::Ruote::ParticipantEntry.new(["^.+$", ["Ruote::StorageParticipant", {}]])
          dashboard.participant_list = dashboard.participant_list.push(catchall)
        end
      end

      def load_participants
        all_files(participants_directory) do |name, path|
          Object.autoload name.to_sym, path
        end
      end

      def participant_block
        raise UnsupportedMode unless @env == 'test'
        @participant_block
      end

    end
  end
end
