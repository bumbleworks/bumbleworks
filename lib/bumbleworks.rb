require "bumbleworks/version"
require "bumbleworks/helpers/ruote"
require "bumbleworks/helpers/participant"
require "bumbleworks/helpers/definition"
require "bumbleworks/configuration"
require "bumbleworks/support"
require "bumbleworks/process_definition"
require "bumbleworks/task"
require "ruote"
require "ruote/reader"
require "ruote-redis"
require "ruote-sequel"
require "forwardable"

module Bumbleworks
  class UnsupportedMode < StandardError; end
  class UndefinedSetting < StandardError; end
  class InvalidSetting < StandardError; end

  class << self
    extend Forwardable
    attr_accessor :env
    include Helpers::Ruote
    include Helpers::Participant
    include Helpers::Definition

    Configuration.defined_settings.each do |setting|
      def_delegators :configuration, setting, "#{setting.to_s}="
    end

    # @public
    # Returns the global configuration, or initializes a new
    # configuration object if it doesn't exist yet.
    def configuration
      @configuration ||= Bumbleworks::Configuration.new
    end

    # @public
    # Yields the global configurtion to a block.
    # @yield [configuration] global configuration
    #
    # @example
    #   Bumbleworks.configure do |c|
    #     c.root = 'path/to/ruote/assets'
    #   end
    # @see Bumbleworks::Configuration
    def configure(&block)
      unless block
        raise ArgumentError.new("You tried to .configure without a block!")
      end
      yield configuration
    end

    # @public
    # Same as .configure, but clears all existing configuration
    # settings first.
    # @yield [configuration] global configuration
    # @see Bumbleworks.configure
    def configure!(&block)
      @configuration = nil
      configure(&block)
    end

    # @public
    # Accepts a block for registering participants which
    # is envoked when start! is called. Notice that a
    # 'catchall' storage participant is always added to
    # the end of the list (unless it is defined in the block).
    #
    # @example
    #   Bumbleworks.register_participants do
    #     painter PainterClass
    #     builder BuilderClass
    #     plumber PlumberClass
    #   end
    def register_participants(&block)
      @participant_block = block
    end

    # @public
    # Adds the process name and definition to the registraton queue.
    # Raises an error if the process name has already been encountered.
    #
    # @example
    #   Bumbleworks.define_process 'build_house' do
    #     contractor :task => 'schedule'
    #   end
    def define_process(name, *args, &block)
      if registered_process_definitions[name]
        raise DefinitionDuplicate, "the process '#{name}' has already been defined"
      end

      registered_process_definitions[name] = ProcessDefinition.define_process(name, *args, &block)
    end

    # @public
    # Starts a Ruote engine, sets up the storage and registers participants
    # and process_definitions with the Ruote engine.
    def start!
      load_participants
      register_participant_list
      load_process_definitions
      register_process_definitions
    end

    # @public
    # Resets Bumbleworks - clears configuration and setup variables, and
    # shuts down the dashboard.
    def reset!
      @configuration = nil
      @participant_block = nil
      shutdown_dashboard
    end

    # @public
    # Launches the workflow engine with the specified process name.
    # The process_definiton_name should already be registered with
    # Bumbleworks.
    def launch!(process_definition_name, options = {})
      register_process_definitions
      autostart = options.delete(:autostart_worker)

      dashboard.launch(dashboard.variables[process_definition_name], options)
    end
  end
end
