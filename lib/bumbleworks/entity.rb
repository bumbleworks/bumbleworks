module Bumbleworks
  module Entity
    def self.included(klass)
      klass.extend ClassMethods
    end

    def launch_process(process_name, options = {})
      identifier_column = self.class.processes[process_name.to_sym][:column]
      if (options[:force] == true || (process_identifier = self.send(identifier_column)).nil?)
        workitem_fields = process_fields(process_name.to_sym)
        variables = process_variables(process_name.to_sym)
        process_identifier = Bumbleworks.launch!(process_name.to_s, workitem_fields, variables).wfid
        persist_process_identifier(identifier_column.to_sym, process_identifier)
      end
      Bumbleworks::Process.new(process_identifier)
    end

    def persist_process_identifier(identifier_column, process_identifier)
      if self.respond_to?(:update)
        update(identifier_column => process_identifier)
      else
        raise "Entity must define #persist_process_identifier method if missing #update method."
      end
    end

    def processes_by_name
      return {} unless self.class.processes
      process_names = self.class.processes.keys
      process_names.inject({}) do |memo, name|
        pid = self.send(self.class.processes[name][:column])
        memo[name] = pid ? Bumbleworks::Process.new(pid) : nil
        memo
      end
    end

    def processes
      processes_by_name.values.compact
    end

    def cancel_all_processes!
      processes.each do |process|
        process.cancel!
      end
    end

    def tasks(nickname = nil)
      finder = Bumbleworks::Task.for_entity(self)
      finder = finder.by_nickname(nickname) if nickname
      finder
    end

    def process_fields(process_name = nil)
      { :entity => self }
    end

    def process_variables(process_name = nil)
      {}
    end

    def subscribed_events
      processes.values.compact.map(&:subscribed_events).flatten.uniq
    end

    def is_waiting_for?(event)
      subscribed_events.include? event.to_s
    end

    module ClassMethods
      attr_reader :processes

      def process(process_name, options = {})
        options[:column] ||= process_identifier_column(process_name)
        (@processes ||= {})[process_name.to_sym] = options
      end

      def entity_type
        Bumbleworks::Support.tokenize(name)
      end

      def process_identifier_column(process_name)
        identifier_column = "#{process_name}_process_identifier"
        identifier_column.gsub!(/^#{entity_type}_/, '')
        identifier_column.gsub!(/process_process/, 'process')
        identifier_column.to_sym
      end
    end
  end
end