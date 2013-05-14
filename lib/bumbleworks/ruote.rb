require "ruote"

module Bumbleworks
  class Ruote
    class << self
      def dashboard(options = {})
        @dashboard ||= begin
          context = if Bumbleworks.autostart_worker || options[:start_worker] == true
            ::Ruote::Worker.new(storage)
          else
            storage
          end
          ::Ruote::Dashboard.new(context)
        end
      end

      def start_worker!(options = {})
        @dashboard = nil
        dashboard(:start_worker => true)
        dashboard.join if options[:join] == true
        dashboard.worker
      end

      def launch(name, options)
        dashboard.launch(dashboard.variables[name], options)
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