require "ruote"
require_relative "worker.rb"

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
        set_up_storage_history
        register_error_dispatcher
        dashboard.noisy = options[:verbose] == true
        worker = Bumbleworks::Worker.new(dashboard.context)
        if options[:join] == true
          worker.run
        else
          worker.run_in_thread
        end
        worker
      end

      def launch(name, *args)
        set_catchall_if_needed
        definition = Bumbleworks::ProcessDefinition.find_by_name(name)
        dashboard.launch(definition.tree, *args)
      end

      def cancel_process!(wfid, options = {})
        unless options[:method] == :kill
          options[:method] = :cancel
        end

        if options[:method] == :cancel || !options[:force]
          dashboard.send(options[:method], wfid)
        else
          storage.remove_process(wfid)
        end

        Bumbleworks::Support.wait_until(options) do
          dashboard.process(wfid).nil?
        end
      rescue Bumbleworks::Support::WaitTimeout
        error_type = options[:method] == :cancel ? CancelTimeout : KillTimeout
        raise error_type, "Process #{options[:method]} for wfid '#{wfid}' taking too long.  Errors: #{dashboard.errors(wfid)}"
      end

      def kill_process!(wfid, options = {})
        cancel_process!(wfid, options.merge(:method => :kill))
      end

      def cancel_all_processes!(options = {})
        unless options[:method] == :kill
          options[:method] = :cancel
        end

        notified_process_wfids = []

        Bumbleworks::Support.wait_until(options) do
          new_process_wfids = dashboard.process_wfids - notified_process_wfids
          if options[:method] == :cancel || !options[:force]
            send_cancellation_message(options[:method], new_process_wfids)
          else
            safe_storage_clear
          end
          notified_process_wfids += new_process_wfids
          dashboard.process_wfids.count == 0
        end
      rescue Bumbleworks::Support::WaitTimeout
        error_type = options[:method] == :cancel ? CancelTimeout : KillTimeout
        raise error_type, "Process #{options[:method]} taking too long - #{dashboard.process_wfids.count} processes remain.  Errors: #{dashboard.errors}"
      end

      def send_cancellation_message(method, process_wfids)
        process_wfids.each do |wfid|
          dashboard.send(method, wfid)
        end
      end

      def kill_all_processes!(options = {})
        cancel_all_processes!(options.merge(:method => :kill))
      end

      def register_participants(&block)
        dashboard.register(&block) if block
        register_entity_interactor
        register_error_dispatcher
        set_catchall_if_needed
        dashboard.participant_list
      end

      def register_entity_interactor
        unless dashboard.participant_list.any? { |part| part.regex == "^(ask|tell)_entity$" }
          entity_interactor = ::Ruote::ParticipantEntry.new(["^(ask|tell)_entity$", ["Bumbleworks::EntityInteractor", {}]])
          dashboard.participant_list = dashboard.participant_list.unshift(entity_interactor)
        end
      end

      def register_error_dispatcher
        unless dashboard.participant_list.any? { |part| part.regex == '^error_dispatcher$' }
          error_dispatcher = ::Ruote::ParticipantEntry.new(['^error_dispatcher$', ["Bumbleworks::ErrorDispatcher", {}]])
          dashboard.participant_list = dashboard.participant_list.unshift(error_dispatcher)
          dashboard.on_error = 'error_dispatcher'
        end
      end

      def set_up_storage_history
        if Bumbleworks.store_history? && Bumbleworks.storage_adapter.allow_history_storage?
          dashboard.add_service('history', 'ruote/log/storage_history', 'Ruote::StorageHistory')
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
        @storage ||= initialize_storage_adapter
      end

      def safe_storage_clear
        Worker.pause_all
        if storage.respond_to?(:redis)
          storage.redis.del("msgs")
        end
        storage.clear
        Worker.unpause_all
      end

      def reset!
        if Bumbleworks.storage && storage
          storage.purge!
          storage.shutdown
        end
        @dashboard.shutdown if @dashboard && @dashboard.respond_to?(:shutdown)
        @storage = nil
        @dashboard = nil
      end

    private

      def initialize_storage_adapter
        Bumbleworks.storage_adapter.new_storage(Bumbleworks.storage, Bumbleworks.storage_options)
      end
    end
  end
end
