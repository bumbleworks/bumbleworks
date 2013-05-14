require "forwardable"
require "bumbleworks/version"
require "bumbleworks/configuration"
require "bumbleworks/support"
require "bumbleworks/process_definition"
require "bumbleworks/task"
require "bumbleworks/participant_registration"
require "bumbleworks/ruote"
require "bumbleworks/hash_storage"

module Bumbleworks
  class UnsupportedMode < StandardError; end
  class UndefinedSetting < StandardError; end
  class InvalidSetting < StandardError; end

  class << self
    extend Forwardable
    attr_accessor :env

    Configuration.defined_settings.each do |setting|
      def_delegators :configuration, setting, "#{setting.to_s}="
    end

    def_delegators Bumbleworks::Ruote, :dashboard, :start_worker!
    def_delegator Bumbleworks::ProcessDefinition, :define, :define_process

    # @public
    # Returns the global configuration, or initializes a new
    # configuration object if it doesn't exist yet.
    def configuration
      @configuration ||= begin
        configuration = Bumbleworks::Configuration.new
        configuration.add_storage_adapter(Bumbleworks::HashStorage)
        if defined?(Bumbleworks::Redis::Adapter) && Bumbleworks::Redis::Adapter.auto_register?
          configuration.add_storage_adapter(Bumbleworks::Redis::Adapter)
        end
        if defined?(Bumbleworks::Sequel::Adapter) && Bumbleworks::Sequel::Adapter.auto_register?
          configuration.add_storage_adapter(Bumbleworks::Sequel::Adapter)
        end
        configuration
      end
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
    # Starts a Ruote engine, sets up the storage and registers participants
    # and process_definitions with the Ruote engine.
    def start!
      autoload_and_register_participants
      load_process_definitions
    end

    # @public
    # Resets Bumbleworks - clears configuration and setup variables, and
    # shuts down the dashboard.
    def reset!
      @configuration = nil
      @participant_block = nil
      @registered_process_definitions = nil
      Bumbleworks::Ruote.reset!
    end

    # @public
    # Launches the workflow engine with the specified process name.
    # The process_definiton_name should already be registered with
    # Bumbleworks.
    def launch!(process_definition_name, options = {})
      Bumbleworks::Ruote.launch(process_definition_name, options)
    end

  private

    def autoload_and_register_participants
      Bumbleworks::ParticipantRegistration.autoload_all
      Bumbleworks::Ruote.register_participants(&@participant_block)
    end

    def load_process_definitions
      Bumbleworks::ProcessDefinition.create_all_from_directory!(definitions_directory)
    end
  end
end
