module Bumbleworks
  module Helpers
    module Definition
      # @private
      def load_process_definitions
        Bumbleworks::Support.all_files(definitions_directory) do |path|
          ProcessDefinition.create!(path)
        end
      end

      # @private
      def registered_process_definitions
        @registered_process_definitions ||= {}
      end

      # @private
      def register_process_definitions
        registered_process_definitions.each do |name,process_definition|
          dashboard.variables[name] = process_definition
        end
      end

      # @private
      def clear_process_definitons
        registered_process_definitions.keys.each do |k|
          dashboard.variables[name] = nil
        end
        @registered_process_definitions = nil
      rescue UndefinedSetting  # storage might not be setup yet
      end
    end
  end
end
