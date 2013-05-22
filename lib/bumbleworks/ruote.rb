require "ruote"

module Bumbleworks
  class Ruote
    class << self
      def dashboard(options = {})
        @dashboard ||= begin
          context = if options[:start_worker] == true
            ::Ruote::Worker.new(storage)
          else
            storage
          end
          ::Ruote::Dashboard.new(context)
        end
      end

      # Start a worker, which will begin polling for messages in
      # the workflow storage.  You can run multiple workers if you
      # are using a storage that supports them (such as Sequel or
      # Redis, but not Hash) - they all just have to be connected
      # to the same storage, and be able to instantiate participants
      # in the participant list.
      #
      # @param [Hash] options startup options for the worker
      # @option options [Boolean] :verbose whether or not to spin up
      #   a "noisy" worker, which will output all messages picked up
      # @option options [Boolean] :join whether or not to join the worker
      #   thread; if false, this method will return, and the worker
      #   thread will be disconnected, and killed if the calling process
      #   exits.
      #
      def start_worker!(options = {})
        @dashboard = nil
        dashboard(:start_worker => true)
        dashboard.noisy = options[:verbose] == true
        dashboard.join if options[:join] == true
        dashboard.worker
      end

      def launch(name, *args)
        dashboard.launch(dashboard.variables[name], *args)
      end

      def register_participants(&block)
        dashboard.register(&block) if block
        set_catchall_if_needed
        dashboard.participant_list
      end

      def set_catchall_if_needed
        last_participant = dashboard.participant_list.last
        unless last_participant && last_participant.regex == "^.+$" && last_participant.classname == "Ruote::StorageParticipant"
          catchall = ::Ruote::ParticipantEntry.new(["^.+$", ["Ruote::StorageParticipant", {}]])
          dashboard.participant_list = dashboard.participant_list.push(catchall)
        end
      end

      def storage
        @storage ||= begin
          all_adapters = Bumbleworks.configuration.storage_adapters
          adapter = all_adapters.detect do |adapter|
            adapter.use?(Bumbleworks.storage)
          end
          raise UndefinedSetting, "Storage is missing or not supported.  Supported: #{all_adapters.map(&:display_name).join(', ')}" unless adapter
          adapter.driver.new(Bumbleworks.storage)
        end
      end

      def reset!
        if @storage
          @storage.purge!
          @storage.shutdown
        end
        @dashboard.shutdown if @dashboard && @dashboard.respond_to?(:shutdown)
        @storage = nil
        @dashboard = nil
      end
    end
  end
end