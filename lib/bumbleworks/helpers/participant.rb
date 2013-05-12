module Bumbleworks
  module Helpers
    module Participant
      # @private
      def register_participant_list
        if @participant_block.is_a? Proc
          dashboard.register &@participant_block
        end

        unless dashboard.participant_list.any? {|pl| pl.regex == "^.+$"}
          catchall = ::Ruote::ParticipantEntry.new(["^.+$", ["Ruote::StorageParticipant", {}]])
          dashboard.participant_list = dashboard.participant_list.push(catchall)
        end
      end

      # @private
      def load_participants
        Bumbleworks::Support.all_files(participants_directory) do |path, name|
          Object.autoload name.to_sym, path
        end
      end

      # @private
      def participant_block
        raise UnsupportedMode unless @env == 'test'
        @participant_block
      end

    end
  end
end
