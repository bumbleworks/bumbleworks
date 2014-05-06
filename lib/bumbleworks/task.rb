require "bumbleworks/workitem_entity_storage"
require "bumbleworks/task/base"
require "bumbleworks/task/finder"

module Bumbleworks
  class Task
    include WorkitemEntityStorage

    class AlreadyClaimed < StandardError; end
    class MissingWorkitem < StandardError; end
    class NotCompletable < StandardError; end
    class AvailabilityTimeout < StandardError; end

    extend Forwardable
    delegate [:sid, :fei, :fields, :dispatched_at, :params, :participant_name, :wfid, :wf_name] => :@workitem
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
        if directory = options[:directory] || Bumbleworks.tasks_directory
          Bumbleworks::Support.all_files(directory, :camelize => true).each do |path, name|
            Object.autoload name.to_sym, path
          end
        end
      end

      def method_missing(method, *args, &block)
        if Finder.new.respond_to?(method)
          return Finder.new(self).send(method, *args, &block)
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
      extend Bumbleworks::Task::Base
      begin
        extend task_module if nickname
      rescue NameError
      end
    end

    def task_module
      return nil unless nickname
      klass_name = Bumbleworks::Support.camelize(nickname)
      klass = Bumbleworks::Support.constantize("#{klass_name}Task")
    end

    def call_before_hooks(action, *args)
      call_hooks(:before, action, *args)
    end

    def call_after_hooks(action, *args)
      call_hooks(:after, action, *args)
    end

    def with_hooks(action, *args, &block)
      call_before_hooks(action, *args)
      yield
      call_after_hooks(action, *args)
    end

    # update workitem with changes to fields & params
    def update(metadata = {})
      with_hooks(:update, metadata) do
        update_workitem
        log(:update, metadata)
      end
    end

    # proceed workitem (saving changes to fields)
    def complete(metadata = {})
      raise NotCompletable.new(not_completable_error_message) unless completable?
      with_hooks(:update, metadata) do
        with_hooks(:complete, metadata) do
          proceed_workitem
          log(:complete, metadata)
        end
      end
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
      with_hooks(:claim, token) do
        set_claimant(token)
        log(:claim)
      end
    end

    # true if task is claimed
    def claimed?
      !claimant.nil?
    end

    # release claim on task.
    def release
      current_claimant = claimant
      with_hooks(:release, current_claimant) do
        log(:release)
        set_claimant(nil)
      end
    end

    def on_dispatch
      log(:dispatch)
      call_after_hooks(:dispatch)
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

    def to_s(options = {})
      titleize(options)
    end

    def titleize(options = {})
      displayify(:titleize, options)
    end

    def humanize(options = {})
      displayify(:humanize, options)
    end

  private
    def call_hooks(phase, action, *args)
      (Bumbleworks.observers + [self]).each do |observer|
        observer.send(:"#{phase}_#{action}", *args)
      end
    end

    def displayify(modifier, options = {})
      task_name = Bumbleworks::Support.send(modifier, nickname)

      if options[:entity] != false && !(entity_fields = entity_fields(modifier => true)).empty?
        "#{task_name}: #{entity_fields[:type]} #{entity_fields[:identifier]}"
      else
        task_name
      end
    end

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
