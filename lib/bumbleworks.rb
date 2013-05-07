require "bumbleworks/version"
require "bumbleworks/helpers"
require "bumbleworks/configuration"
require "bumbleworks/support"
require "bumbleworks/process_definition"
require "bumbleworks/task"
require "ruote"
require "ruote/reader"
require "ruote-redis"
require "ruote-sequel"

module Bumbleworks
  class UnsupportedMode < StandardError; end
  class UndefinedSetting < StandardError; end
  class InvalidSetting < StandardError; end

  class << self
    extend Forwardable
    attr_accessor :env
    include Helpers

    Configuration.defined_settings.each do |setting|
      def_delegators :configuration, setting, "#{setting.to_s}="
    end

    def configure
      reset!
      yield configuration if block_given?
    end

    def register_participants(&block)
      @participant_block = block
    end

    def define_process(name, *args, &block)
      if registered_process_definitions[name]
        raise DefinitionDuplicate, "the process '#{name}' has already been defined"
      end

      registered_process_definitions[name] = ProcessDefinition.define_process(name, *args, &block)
    end

    def start!
      load_participants
      register_participant_list
      load_process_definitions
      register_process_definitions
    end

    def launch!(process_definition_name, options = {})
      register_process_definitions
      autostart = options.delete(:autostart_worker)

      dashboard.launch(dashboard.variables[process_definition_name], options)
    end
  end
end
