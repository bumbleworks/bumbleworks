module Bumbleworks
  module Helpers
    module Ruote
      def dashboard
        @dashboard ||= ::Ruote::Dashboard.new(::Ruote::Worker.new(ruote_storage))
      end

      def ruote_storage
        @ruote_storage ||= case storage.class.name
          when /^Redis/  then ::Ruote::Redis::Storage.new(storage)
          when /^Hash/   then ::Ruote::HashStorage.new(storage)
          when /^Sequel/ then ::Ruote::Sequel::Storage.new(storage)
          else
            raise UndefinedSetting, "Storage is missing or not supported. Redis, Sequel or Hash are the only supported storge adapters" unless storage
        end
      end

      def shutdown_dashboard
        clear_process_definitons
        if @ruote_storage
          @ruote_storage.purge!
          @ruote_storage.shutdown
        end
        @dashboard.shutdown if @dashboard && @dashboard.respond_to?(:shutdown)
        @ruote_storage = nil
        @dashboard = nil
      end
    end
  end
end
