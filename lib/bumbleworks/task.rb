require "bumbleworks/tasks/base"
require "bumbleworks/workitem_entity_storage"
require "bumbleworks/task/finder"

module Bumbleworks
  class Task
    include WorkitemEntityStorage

    class AlreadyClaimed < StandardError; end
    class MissingWorkitem < StandardError; end
    class NotCompletable < StandardError; end
    class AvailabilityTimeout < StandardError; end

    extend Forwardable
    delegate [:sid, :fei, :fields, :params, :participant_name, :wfid, :wf_name] => :@workitem
    attr_reader :nickname, :workitem
    alias_method :id, :sid

    class << self
      # @public
      # Autoload all task modules defined in files in the
      # tasks_directory.  The symbol for autoload comes from the
      # camelized version of the filename, so this method is dependent on
      # following that convention.  For example, file `chew_cud_task.rb`
      # should define `ChewCudTask`.
      #
      def autoload_all(options = {})
        options[:directory] ||= Bumbleworks.tasks_directory
        Bumbleworks::Support.all_files(options[:directory], :camelize => true).each do |path, name|
          Object.autoload name.to_sym, path
        end
      end

      def method_missing(method, *args)
        if Finder.new.respond_to?(method)
          return Finder.new.send(method, *args)
        end
        super
      end

      def find_by_id(sid)
        workitem = storage_participant[sid] if sid
        raise MissingWorkitem unless workitem
        new(workitem)
      rescue ArgumentError => e
        raise MissingWorkitem, e.message
      end

      def storage_participant
        Bumbleworks.dashboard.storage_participant
      end
    end

    def initialize(workitem)
      @workitem = workitem
      unless workitem && workitem.is_a?(::Ruote::Workitem)
        raise ArgumentError, "Not a valid workitem"
      end
      @nickname = params['task']
      extend_module
    end

    def reload
      @workitem = storage_participant[sid]
      self
    end

    # alias for fields[] (fields delegated to workitem)
    def [](key)
      fields[key]
    end

    # alias for fields[]= (fields delegated to workitem)
    def []=(key, value)
      fields[key] = value
    end

    def role
      participant_name
    end

    def extend_module
      extend Bumbleworks::Tasks::Base
      extend task_module if nickname
    rescue NameError
    end

    def task_module
      return nil unless nickname
      klass_name = Bumbleworks::Support.camelize(nickname)
      klass = Bumbleworks::Support.constantize("#{klass_name}Task")
    end

    # update workitem with changes to fields & params
    def update(metadata = {})
      before_update(metadata)
      update_workitem
      log(:update, metadata)
      after_update(metadata)
    end

    # proceed workitem (saving changes to fields)
    def complete(metadata = {})
      raise NotCompletable.new(not_completable_error_message) unless completable?
      before_update(metadata)
      before_complete(metadata)
      proceed_workitem
      log(:complete, metadata)
      after_complete(metadata)
      after_update(metadata)
    end

    # Token used to claim task, nil if not claimed
    def claimant
      params['claimant']
    end

    # Timestamp of last claim, nil if not currently claimed
    def claimed_at
      params['claimed_at']
    end

    # Claim task and assign token to claimant
    def claim(token)
      before_claim(token)
      set_claimant(token)
      log(:claim)
      after_claim(token)
    end

    # true if task is claimed
    def claimed?
      !claimant.nil?
    end

    # release claim on task.
    def release
      current_claimant = claimant
      before_release(current_claimant)
      log(:release)
      set_claimant(nil)
      after_release(current_claimant)
    end

    def on_dispatch
      log(:dispatch)
      after_dispatch
    end

    def log(action, metadata = {})
      Bumbleworks.logger.info({
        :actor => params['claimant'],
        :action => action,
        :target_type => 'Task',
        :target_id => id,
        :metadata => metadata.merge(:current_fields => fields)
      })
    end

  private

    def storage_participant
      self.class.storage_participant
    end

    def update_workitem
      storage_participant.update(@workitem)
    end

    def proceed_workitem
      storage_participant.proceed(@workitem)
    end

    def set_claimant(token)
      if token && claimant && token != claimant
        raise AlreadyClaimed, "Already claimed by #{claimant}"
      end

      params['claimant'] = token
      params['claimed_at'] = token ? Time.now : nil
      update_workitem
    end
  end
end
