require "bumbleworks/workitem_entity_storage"
require "bumbleworks/process/error_record"

module Bumbleworks
  class Process
    class EntityConflict < StandardError; end

    include WorkitemEntityStorage

    attr_reader :id

    class << self
      def all(options = {})
        ids(options).map do |wfid|
          new(wfid)
        end
      end

      def ids(options = {})
        wfids = Bumbleworks.dashboard.process_wfids
        wfids.reverse! if options[:reverse]
        limit = options[:limit] || wfids.count
        offset = options[:offset] || 0
        wfids[offset, limit]
      end

      def count
        ids.count
      end
    end

    def initialize(wfid)
      @id = wfid
    end

    def reload
      (instance_variables - [:@id]).each do |memo|
        instance_variable_set(memo, nil)
      end
      self
    end

    alias_method :wfid, :id

    def <=>(other)
      wfid <=> other.wfid
    end

    def ==(other)
      wfid == other.wfid
    end

    def entity_workitem
      @entity_workitem ||= if workitems.map(&:entity_fields).uniq.length <= 1
        workitems.first
      else
        raise EntityConflict
      end
    end

    def entity_storage_workitem
      super(entity_workitem)
    end

    def expressions
      @expressions ||= ruote_expressions.map { |rexp|
        Bumbleworks::Expression.new(rexp)
      }
    end

    def expression_at_position(position)
      expressions.detect { |exp| exp.expid == position }
    end

    def errors
      @errors ||= Bumbleworks.dashboard.context.storage.get_many('errors', [wfid]).map { |err|
        Bumbleworks::Process::ErrorRecord.new(
          ::Ruote::ProcessError.new(err)
        )
      }
    end

    def leaves
      @leaves ||= ruote_expressions.inject([]) { |a, exp|
        a.select { |e| ! exp.ancestor?(e.fei) } + [ exp ]
      }.map { |leaf|
        Bumbleworks::Expression.new(leaf)
      }
    end

    def workitems
      @workitems ||= leaves.map(&:workitem)
    end

    def tasks
      @tasks ||= Bumbleworks::Task.for_process(wfid)
    end

    def trackers
      @trackers ||= Bumbleworks.dashboard.get_trackers.select { |tid, attrs|
        attrs['msg']['fei'] && attrs['msg']['fei']['wfid'] == id
      }.map { |tid, original_hash|
        Bumbleworks::Tracker.new(tid, original_hash)
      }
    end

    def all_subscribed_tags
      @all_subscribed_tags ||= trackers.inject({ :global => [] }) do |memo, t|
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
      @process_status ||= Bumbleworks.dashboard.process(id)
    end

    def definition_name
      root_ruote_expression.attribute('name') ||
        root_ruote_expression.attribute_text
    end

    def method_missing(method, *args)
      ps = process_status
      if ps.respond_to?(method)
        return ps.send(method, *args)
      end
      super
    end

  private

    def root_ruote_expression
      @root_ruote_expression ||= ruote_expressions.first
    end

    def ruote_expressions
      @ruote_expressions ||= begin
        context = Bumbleworks.dashboard.context
        raw_expressions = context.storage.get_many('expressions', [wfid])
        raw_expressions.collect { |e|
          ::Ruote::Exp::FlowExpression.from_h(context, e)
        }.sort_by { |e|
          e.fei.expid
        }
      end
    end
  end
end