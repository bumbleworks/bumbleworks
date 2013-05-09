module Bumbleworks
  class ClaimError < StandardError; end

  class Task
    extend Forwardable
    delegate [:sid, :fei, :fields, :params, :participant_name, :wfid, :wf_name] => :@workitem
    alias_method :id, :sid

    class << self
      def for_actor(identifier)
        storage_participant.by_participant(identifier).map(&to_task)
      end

      def all
        storage_participant.all.map(&to_task)
      end

      def storage_participant
        Bumbleworks.dashboard.storage_participant
      end

      def to_task
        lambda {|wi| new(wi)}
      end
    end

    def initialize(workitem)
      @workitem = workitem
    end

    # alias for params[]
    def [](key)
      params[key]
    end

    def []=(key, value)
      params[key] = value
    end

    def nickname
      params['task'] || 'unspecified'
    end

    # update workitem with changes to params
    def save
      storage_participant.update(@workitem)
    end

    # proceed workitem
    def complete
      storage_participant.proceed(@workitem)
    end

    # Claim task and assign token to claim
    def claim(token)
      if token && claimant && token != claimant
        raise ClaimError, "Already claimed by #{claimant}"
      end

      params['claimant'] = token
      save
    end

    # Token used to claim task, nil if not claimed
    def claimant
      params['claimant']
    end

    # true if task is claimed
    def claimed?
      !claimant.nil?
    end

    # release claim on task.
    def release
      claim(nil)
    end

    private
    def storage_participant
      self.class.storage_participant
    end
  end
end
