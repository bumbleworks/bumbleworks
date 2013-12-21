module Bumbleworks
  class Process
    attr_reader :id

    def initialize(wfid)
      @id = wfid
    end

    alias_method :wfid, :id

    def ==(other)
      wfid == other.wfid
    end

    def tasks
      Bumbleworks::Task.for_process(wfid)
    end

    def trackers
      Bumbleworks.dashboard.get_trackers.values.select { |attrs|
        attrs['msg']['fei'] && attrs['msg']['fei']['wfid'] == id
      }
    end

    def all_subscribed_tags
      events = trackers.inject({}) do |memo, t|
        if t['wfid'].nil?
          (memo[:global] ||= []).concat t['conditions']['tag']
        else
          (memo[t['wfid']] ||= []).concat t['conditions']['tag']
        end
        memo
      end
    end

    def subscribed_events
      all_subscribed_tags[:global]
    end

    def is_waiting_for?(event)
      subscribed_events.include? event.to_s
    end

    def kill!
      Bumbleworks.kill_process!(wfid)
    end

    def cancel!
      Bumbleworks.cancel_process!(wfid)
    end

    def process_status
      Bumbleworks.dashboard.process(id)
    end

    def method_missing(method, *args)
      ps = process_status
      if ps.respond_to?(method)
        return ps.send(method, *args)
      end
      super
    end
  end
end