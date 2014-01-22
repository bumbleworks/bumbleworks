module Bumbleworks
  class Process
    class EntityConflict < StandardError; end

    attr_reader :id

    class << self
      def all
        Bumbleworks.dashboard.process_wfids.map do |wfid|
          new(wfid)
        end
      end
    end

    def initialize(wfid)
      @id = wfid
    end

    alias_method :wfid, :id

    def ==(other)
      wfid == other.wfid
    end

    def entity
      return nil unless process_status
      workitems = leaves.map(&:applied_workitem).map { |wi| Bumbleworks::Workitem.new(wi) }
      if workitems.map(&:entity_fields).uniq.length == 1
        workitems.first.entity if workitems.first.has_entity?
      else
        raise EntityConflict
      end
    end

    def tasks
      Bumbleworks::Task.for_process(wfid)
    end

    def trackers
      Bumbleworks.dashboard.get_trackers.select { |tid, attrs|
        attrs['msg']['fei'] && attrs['msg']['fei']['wfid'] == id
      }.map { |tid, original_hash|
        Bumbleworks::Tracker.new(tid, original_hash)
      }
    end

    def all_subscribed_tags
      trackers.inject({ :global => [] }) do |memo, t|
        if t.global?
          memo[:global].concat t.tags
        else
          (memo[t.wfid] ||= []).concat t.tags
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