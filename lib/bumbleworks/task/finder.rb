module Bumbleworks
  class Task
    class Finder
      include Enumerable

      def initialize(queries = [], task_class = Bumbleworks::Task)
        @queries = queries
        @task_class = task_class
        @task_filters = []
        @orderers = []
        @wfids = nil
        add_query { |wi| wi['fields']['params']['task'] }
      end

      def where(filters)
        key_method_map = {
          :available => :available,
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
        fields = filters.select { |k,v| !key_method_map.keys.include? k }
        methods = filters.select { |k,v| key_method_map.keys.include? k }
        query = methods.inject(self) { |query, (method, args)|
          query.send(key_method_map[method], args)
        }
        unless fields.empty?
          query.with_fields(fields)
        end
        query
      end

      def available
        unclaimed.completable
      end

      def by_nickname(nickname)
        add_query { |wi| wi['fields']['params']['task'] == nickname }
      end

      def for_roles(identifiers)
        identifiers ||= []
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

      def add_query(&block)
        @queries << block
        self
      end

      def add_filter(&block)
        @task_filters << block
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
        workitems = raw_workitems(@wfids)
        @orderers.each do |order_proc|
          workitems.sort! &order_proc
        end
        workitems.each { |wi|
          if task = filtered_task_from_raw_workitem(wi)
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

    private

      def add_orderer(fields, field_type = 'fields')
        @orderers << proc { |wi_x, wi_y|
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

      def filtered_task_from_raw_workitem(workitem)
        if @queries.all? { |q| q.call(workitem) }
          task = from_workitem(::Ruote::Workitem.new(workitem))
          task if check_filters(task)
        end
      end

      def check_filters(task)
        @task_filters.all? { |f| f.call(task) }
      end

      def from_workitem(workitem)
        task = @task_class.new(workitem)
      end

      def raw_workitems(wfids)
        Bumbleworks.dashboard.context.storage.get_many('workitems', wfids)
      end
    end
  end
end
