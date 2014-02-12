module Bumbleworks
  class Task
    class Finder
      class WorkitemQuery < Proc; end
      class TaskQuery < Proc; end

      WhereKeyToMethodMap = {
        :available => :available,
        :unavailable => :unavailable,
        :nickname => :by_nickname,
        :roles => :for_roles,
        :role => :for_role,
        :unclaimed => :unclaimed,
        :claimed => :claimed,
        :fields => :with_fields,
        :claimant => :for_claimant,
        :entity => :for_entity,
        :processes => :for_processes,
        :process => :for_process,
        :completable => :completable
      }

      include Enumerable

      def initialize(task_class = Bumbleworks::Task)
        @task_class = task_class
        @queries = []
        @orderers = []
        @wfids = nil
        @join = :all
      end

      def where_any(query_group = {})
        set_join_for_query_group(query_group, :any)
      end

      def where_all(query_group = {})
        set_join_for_query_group(query_group, :all)
      end

      def where(filters, group_type = nil)
        group_type = :all unless group_type == :any
        if group_type != @join
          finder = self.class.new(@task_class)
          finder.send(:"where_#{group_type}")
        else
          finder = self
        end
        finder = filters.inject(finder) { |query_target, (key, args)|
          if method = WhereKeyToMethodMap[key]
            query_target.send(method, args)
          else
            query_target.with_fields(key => args)
          end
        }
        finder == self ? self : add_subfinder(finder)
      end

      def available(check = true)
        if check
          where_all(:unclaimed => true, :completable => true)
        else
          where_any(:claimed => true, :completable => false)
        end
      end

      def unavailable(check = true)
        available(!check)
      end

      def by_nickname(nickname)
        add_query { |wi| wi['fields']['params']['task'] == nickname }
      end

      def for_roles(identifiers)
        identifiers ||= []
        identifiers.map! { |i| i.to_s }
        add_query { |wi| identifiers.include?(wi['participant_name']) }
      end

      def for_role(identifier)
        for_roles([identifier])
      end

      def unclaimed(check = true)
        add_query { |wi| wi['fields']['params']['claimant'].nil? == check }
      end

      def claimed(check = true)
        unclaimed(!check)
      end

      def with_fields(field_hash)
        add_query { |wi| field_hash.all? { |k, v| wi['fields'][k.to_s] == v } }
      end

      def for_claimant(token)
        add_query { |wi| wi['fields']['params']['claimant'] == token }
      end

      def for_entity(entity)
        with_fields({
          :entity_type => entity.class.name,
          :entity_id => entity.identifier
        })
      end

      def for_processes(processes)
        process_ids = (processes || []).map { |p|
          p.is_a?(Bumbleworks::Process) ? p.wfid : p
        }
        @wfids = process_ids
        self
      end

      def for_process(process)
        for_processes([process])
      end

      def order_by_field(field, direction = :asc)
        order_by_fields(field => direction)
      end

      def order_by_param(param, direction = :asc)
        order_by_params(param => direction)
      end

      def order_by_fields(fields)
        add_orderer(fields)
      end

      def order_by_params(params)
        add_orderer(params, 'params')
      end

      def completable(true_or_false = true)
        add_filter { |task| task.completable? == true_or_false }
      end

      def add_subfinder(finder)
        @queries << finder
        self
      end

      def add_query(&block)
        @queries << WorkitemQuery.new(&block)
        self
      end

      def add_filter(&block)
        @queries << TaskQuery.new(&block)
        self
      end

      def next_available(options = {})
        options[:timeout] ||= Bumbleworks.timeout

        start_time = Time.now
        while (first_task = first).nil?
          if (Time.now - start_time) > options[:timeout]
            raise @task_class::AvailabilityTimeout, "No tasks found matching criteria in time"
          end
          sleep 0.1
        end
        first_task
      end

      def each
        return to_enum(:each) unless block_given?
        return if @wfids == []
        only_workitem_queries = @queries.all? { |q| q.is_a? WorkitemQuery }
        workitems = raw_workitems(@wfids)
        @orderers.each do |order_proc|
          workitems.sort! &order_proc
        end
        workitems.each { |wi|
          if task = filtered_task_from_raw_workitem(wi, only_workitem_queries)
            yield task
          end
        }
      end

      def all
        to_a
      end

      def empty?
        !any?
      end

      def check_queries(workitem, task)
        grouped_queries(@join).call(workitem, task)
      end

    private

      def add_orderer(fields, field_type = 'fields')
        @orderers << Proc.new { |wi_x, wi_y|
          relevant_direction, result = :asc, 0
          fields.each do |field, direction|
            sets = [wi_x['fields'], wi_y['fields']]
            sets.map! { |s| s['params'] } if field_type.to_s == 'params'
            result = sets[0][field.to_s] <=> sets[1][field.to_s]
            relevant_direction = direction
            break if !result.zero?
          end
          relevant_direction == :desc ? -result : result
        }
        self
      end

      def filtered_task_from_raw_workitem(workitem, only_workitem_queries = false)
        if only_workitem_queries
          if check_queries(workitem, nil)
            task = from_workitem(::Ruote::Workitem.new(workitem))
          end
        else
          task = from_workitem(::Ruote::Workitem.new(workitem))
          task if check_queries(workitem, task)
        end
      end

      def grouped_queries(group_type)
        Proc.new { |wi, task|
          @queries.send(:"#{group_type}?") { |q|
            case q
            when WorkitemQuery
              q.call(wi)
            when TaskQuery
              q.call(task)
            when self.class
              q.check_queries(wi, task)
            else
              raise "Unrecognized query type"
            end
          }
        }
      end

      def from_workitem(workitem)
        task = @task_class.new(workitem)
      end

      def raw_workitems(wfids)
        Bumbleworks.dashboard.context.storage.get_many('workitems', wfids).select { |wi|
          wi['fields']['params']['task']
        }
      end

      def join=(new_join)
        @join = new_join if [:all, :any].include?(new_join)
      end

      def set_join_for_query_group(query_group, type)
        if query_group.empty?
          self.join = type
          self
        else
          where(query_group, type)
        end
      end
    end
  end
end
