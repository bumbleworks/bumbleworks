require "ruote"
require "ruote-redis"
require "ruote-sequel"

module Bumbleworks
  class Ruote
    class << self
      def dashboard
        @dashboard ||= begin
          context = if Bumbleworks.autostart_worker
            ::Ruote::Worker.new(storage)
          else
            storage
          end
          ::Ruote::Dashboard.new(context)
        end
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
          ruote_storage_class = case Bumbleworks.storage.class.name
          when /^Redis/  then ::Ruote::Redis::Storage
          when /^Hash/   then ::Ruote::HashStorage
          when /^Sequel/ then ::Ruote::Sequel::Storage
          else
            raise UndefinedSetting, "Storage is missing or not supported. Redis, Sequel or Hash are the only supported storage adapters"
          end
          ruote_storage_class.new(Bumbleworks.storage)
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