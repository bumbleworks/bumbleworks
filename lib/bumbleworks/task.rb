module Bumbleworks
  class ClaimError < StandardError; end

  class Task
    extend Forwardable
    delegate [:sid, :fei, :fields, :params, :participant_name, :wfid, :wf_name] => :@workitem
    attr_reader :nickname
    alias_method :id, :sid

    class << self
      def for_role(identifier)
        for_roles([identifier])
      end

      def for_roles(identifiers)
        return [] unless identifiers.is_a?(Array)
        identifiers.collect { |identifier|
          storage_participant.by_participant(identifier)
        }.flatten.uniq.map(&to_task)
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
      @nickname = params['task']
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

    # update workitem with changes to fields & params
    def save
      storage_participant.update(@workitem)
    end

    # proceed workitem (saving changes to fields)
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
