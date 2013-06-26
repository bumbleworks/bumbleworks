module Bumbleworks
  class Task
    class AlreadyClaimed < StandardError; end
    class MissingWorkitem < StandardError; end

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
        workitems = identifiers.collect { |identifier|
          storage_participant.by_participant(identifier)
        }.flatten.uniq
        from_workitems(workitems)
      end

      def all
        from_workitems(storage_participant.all)
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

      def from_workitems(workitems)
        workitems.map { |wi|
          new(wi) if wi.params['task']
        }.compact
      end
    end

    def initialize(workitem)
      @workitem = workitem
      unless workitem && workitem.is_a?(::Ruote::Workitem)
        raise ArgumentError, "Not a valid workitem"
      end
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

    # Token used to claim task, nil if not claimed
    def claimant
      params['claimant']
    end

    # Claim task and assign token to claimant
    def claim(token)
      set_claimant(token)
    end

    # true if task is claimed
    def claimed?
      !claimant.nil?
    end

    # release claim on task.
    def release
      set_claimant(nil)
    end

    private
    def storage_participant
      self.class.storage_participant
    end

    def set_claimant(token)
      if token && claimant && token != claimant
        raise AlreadyClaimed, "Already claimed by #{claimant}"
      end

      params['claimant'] = token
      save
    end
  end
end
