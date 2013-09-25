module Bumbleworks
  class Task
    class Finder
      include Enumerable

      def initialize(queries = [], task_class = Bumbleworks::Task)
        @queries = queries
        @task_class = task_class
      end

      def by_nickname(nickname)
        @queries << proc { |wi| wi['fields']['params']['task'] == nickname }
        self
      end

      def for_roles(identifiers)
        identifiers ||= []
        @queries << proc { |wi| identifiers.include?(wi['participant_name']) }
        self
      end

      def for_role(identifier)
        for_roles([identifier])
      end

      def unclaimed(check = true)
        @queries << proc { |wi| wi['fields']['params']['claimant'].nil? == check }
        self
      end

      def claimed
        unclaimed(false)
      end

      def for_claimant(token)
        @queries << proc { |wi| wi['fields']['params']['claimant'] == token }
        self
      end

      def for_entity(entity)
        entity_id = entity.respond_to?(:identifier) ? entity.identifier : entity.id
        @queries << proc { |wi|
          (wi['fields'][:entity_type] || wi['fields']['entity_type']) == entity.class.name &&
            (wi['fields'][:entity_id] || wi['fields']['entity_id']) == entity_id
        }
        self
      end

      def all
        workitems = Bumbleworks.dashboard.storage_participant.send(:do_select, {}) { |wi|
          @queries.all? { |q| q.call(wi) }
        }
        from_workitems(workitems)
      end

      def each(&block)
        all.each(&block)
      end

      def empty?
        all.empty?
      end

      def next_available(options = {})
        options[:timeout] ||= Bumbleworks.timeout

        start_time = Time.now
        while first.nil?
          if (Time.now - start_time) > options[:timeout]
            raise @task_class::AvailabilityTimeout, "No tasks found matching criteria in time"
          end
          current_priority = Process.getpriority(Process::PRIO_PROCESS, 0)
          Process.setpriority(Process::PRIO_PROCESS, 0, 19)
          sleep 0.5
          Process.setpriority(Process::PRIO_PROCESS, 0, current_priority)
        end
        first
      end

    private

      def from_workitems(workitems)
        workitems.map { |wi|
          @task_class.new(wi) if wi.params['task']
        }.compact
      end
    end
  end
end
