require "ruote"

Dir[File.join(File.dirname(__FILE__), 'ruote', 'exp', '*.rb')].each { |f| require f }

module Bumbleworks
  class Ruote
    class CancelTimeout < StandardError; end
    class KillTimeout < StandardError; end

    class << self
      def dashboard(options = {})
        @dashboard ||= ::Ruote::Dashboard.new(storage)
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
        dashboard.noisy = options[:verbose] == true
        worker = ::Ruote::Worker.new(dashboard.context)
        if options[:join] == true
          worker.run
        else
          worker.run_in_thread
        end
        register_error_handler
        worker
      end

      def launch(name, *args)
        set_catchall_if_needed
        dashboard.launch(dashboard.variables[name], *args)
      end

      def cancel_process!(wfid, options = {})
        options[:timeout] ||= Bumbleworks.timeout
        unless options[:method] == :kill
          options[:method] = :cancel
        end

        dashboard.send(options[:method], wfid)
        start_time = Time.now
        while dashboard.process(wfid)
          if (Time.now - start_time) > options[:timeout]
            error_type = options[:method] == :cancel ? CancelTimeout : KillTimeout
            raise error_type, "Process #{options[:method]} taking too long - #{dashboard.processes.count} processes remain.  Errors: #{dashboard.errors}"
          end
          sleep 0.1
        end
      end

      def kill_process!(wfid, options = {})
        cancel_process!(wfid, options.merge(:method => :kill))
      end

      def cancel_all_processes!(options = {})
        options[:timeout] ||= Bumbleworks.timeout
        unless options[:method] == :kill
          options[:method] = :cancel
        end

        notified_processes = []

        start_time = Time.now
        while dashboard.processes.count > 0
          new_processes = dashboard.processes - notified_processes
          send_cancellation_message(options[:method], new_processes)
          notified_processes += new_processes

          if (Time.now - start_time) > options[:timeout]
            error_type = options[:method] == :cancel ? CancelTimeout : KillTimeout
            raise error_type, "Process #{options[:method]} taking too long - #{dashboard.processes.count} processes remain.  Errors: #{dashboard.errors}"
          end
          sleep 0.1
        end
      end

      def send_cancellation_message(method, processes)
        processes.each do |ps|
          dashboard.send(method, ps.wfid)
        end
      end

      def kill_all_processes!(options = {})
        cancel_all_processes!(options.merge(:method => :kill))
      end

      def register_participants(&block)
        dashboard.register(&block) if block
        register_error_handler
        set_catchall_if_needed
        dashboard.participant_list
      end

      def register_error_handler
        unless dashboard.participant_list.any? { |part| part.regex == '^error_handler_participant$' }
          error_handler_participant = ::Ruote::ParticipantEntry.new(['^error_handler_participant$', ["Bumbleworks::ErrorHandlerParticipant", {}]])
          dashboard.participant_list = dashboard.participant_list.unshift(error_handler_participant)
          dashboard.on_error = 'error_handler_participant'
        end
      end

      def set_catchall_if_needed
        last_participant = dashboard.participant_list.last
        unless last_participant && last_participant.regex == "^.+$" &&
            ["Ruote::StorageParticipant", "Bumbleworks::StorageParticipant"].include?(last_participant.classname)
          catchall = ::Ruote::ParticipantEntry.new(["^.+$", ["Bumbleworks::StorageParticipant", {}]])
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
