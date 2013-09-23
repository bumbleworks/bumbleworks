module Bumbleworks
  # Stores configuration information
  #
  # Configuration information is loaded from a configuration block defined within
  # the client application.
  #
  # @example Standard settings
  #   Bumbleworks.configure do |c|
  #     c.definitions_directory = '/path/to/ruote/definitions/directory'
  #     c.storage = Redis.new(:host => '127.0.0.1', :db => 0, :thread_safe => true)
  #     # ...
  #   end
  #
  class Configuration
    attr_reader :storage_adapters

    class << self
      def define_setting(name)
        defined_settings << name
        attr_accessor name
      end

      def defined_settings
        @defined_settings ||= []
      end
    end


    # Path to the root folder where Bumbleworks assets can be found.
    # This includes the following structure:
    #   /lib
    #     /process_definitions
    #   /participants
    #   /app/participants
    #
    # default: none, must be specified
    # Exceptions: raises Bumbleworks::UndefinedSetting if not defined by the client
    #
    define_setting :root

    # Path to the folder which holds the ruote definition files. Bumbleworks
    # will load all definition files by recursively traversing the directory
    # tree under this folder. No specific loading order is guaranteed
    #
    # default: ${Bumbleworks.root}/lib/bumbleworks/process_definitions then ${Bumbleworks.root}/lib/bumbleworks/processes
    define_setting :definitions_directory

    # Path to the folder which holds the ruote participant files. Bumbleworks
    # will recursively traverse the directory tree under this folder and ensure
    # that all found files are autoloaded before registration of participants.
    #
    # default: ${Bumbleworks.root}/lib/bumbleworks/participants
    define_setting :participants_directory

    # Path to the folder which holds the optional task module files, which are
    # used to dynamically extend tasks (to override methods, or implement
    # callbacks). Bumbleworks will recursively traverse the directory tree under
    # this folder and ensure that all found files are autoloaded.
    #
    # default: ${Bumbleworks.root}/lib/bumbleworks/tasks
    define_setting :tasks_directory

    # Bumbleworks requires a dedicated key-value storage for process information.  Three
    # storage solutions are currently supported: Hash, Redis and Sequel.  The latter
    # two require the bumbleworks-redis and bumbleworks-sequel gems, respectively.
    # You can set the storage as follows:
    #
    # @Exammple: Redis
    #   Bumbleworks.storage = Redis.new(:host => '127.0.0.1', :db => 0, :thread_safe => true)
    #
    # @Example: Sequel with Postgres db
    #   Bumbleworks.storage = Sequel.connect('postgres://user:password@host:port/database_name')
    #
    define_setting :storage

    # Bumbleworks will attempt to log a variety of events (tasks becoming
    # available, being claimed/released/completed, etc), and to do so it uses
    # the logger registered in configuration.  If no logger has been registered,
    # Bumbleworks will use its SimpleLogger, which just adds the entries to an
    # array.  See the SimpleLogger for hints on implementing your own logger;
    # notably, you can also use an instance Ruby's built-in Logger class.
    #
    # default: Bumbleworks::SimpleLogger
    define_setting :logger

    # All before_* and after_* callback methods prototyped in Tasks::Base will
    # also be called on all registered observers.
    define_setting :observers

    # Cancelling a process or waiting for a task to become available are both asynchronous actions
    # performed by Ruote.  Bumbleworks waits for the specified timeout before giving up and raising
    # the appropriate Timeout error.
    #
    # default: 5 seconds
    define_setting :timeout

    def initialize
      @storage_adapters = []
      @timeout ||= 5
    end

    # Path where Bumbleworks will look for ruote process defintiions to load.
    # The path can be relative or absolute.  Relative paths are
    # relative to Bumbleworks.root.
    #
    def definitions_directory
      @definitions_folder ||= default_definition_directory
    end

    # Path where Bumbleworks will look for ruote participants to load.
    # The path can be relative or absolute.  Relative paths are
    # relative to Bumbleworks.root.
    #
    def participants_directory
      @participants_folder ||= default_participant_directory
    end

    # Path where Bumbleworks will look for task modules to load.
    # The path can be relative or absolute.  Relative paths are
    # relative to Bumbleworks.root.
    #
    def tasks_directory
      @tasks_folder ||= default_tasks_directory
    end

    # Root folder where Bumbleworks looks for ruote assets (participants,
    # process_definitions, etc.)  The root path must be absolute.
    # It can be defined through a configuration block:
    #   Bumbleworks.configure { |c| c.root = '/somewhere' }
    #
    # Or directly:
    #   Bumbleworks.root = '/somewhere/else/'
    #
    # If the root is not defined, Bumbleworks will use the root of known
    # frameworks (Rails, Sinatra and Rory).  Otherwise, it will raise an
    # error if not defined.
    #
    def root
      @root ||= case
        when defined?(Rails) then Rails.root
        when defined?(Rory) then Rory.root
        when defined?(Padrino) then Padrino.root
        when defined?(Sinatra::Application) then Sinatra::Application.root
      end
      raise UndefinedSetting.new("Bumbleworks.root must be set") unless @root
      @root
    end

    # Add a storage adapter to the set of possible adapters.  Takes an object
    # that responds to `driver`, `use?`, `storage_class`, and `display_name`.
    #
    def add_storage_adapter(adapter)
      raise ArgumentError, "#{adapter} is not a Bumbleworks storage adapter" unless
        [:driver, :use?, :storage_class, :display_name].all? { |m| adapter.respond_to?(m) }

      @storage_adapters << adapter
      @storage_adapters
    end

    def logger
      @logger ||= Bumbleworks::SimpleLogger
    end

    def observers
      @observers ||= []
    end

    # Clears all memoize variables and configuration settings
    #
    def clear!
      defined_settings.each {|setting| instance_variable_set("@#{setting}", nil)}
      @storage_adapters = []
      @definitions_folder = @participants_folder = @tasks_folder = nil
    end

    private
    def defined_settings
      self.class.defined_settings
    end

    def default_definition_directory
      default_folders = ['lib/bumbleworks/process_definitions', 'lib/bumbleworks/processes']
      find_folder(default_folders, @definitions_directory, "Definitions folder not found")
    end

    def default_participant_directory
      default_folders = ['lib/bumbleworks/participants']
      find_folder(default_folders, @participants_directory, "Participants folder not found")
    end

    def default_tasks_directory
      default_folders = ['lib/bumbleworks/tasks']
      find_folder(default_folders, @tasks_directory, "Tasks folder not found")
    end

    def find_folder(default_directories, user_defined_directory, message)
      if user_defined_directory
        # use user-defined directory if specified
        defined_directory = if user_defined_directory[0] == '/'
          user_defined_directory
        else
          File.join(root, user_defined_directory)
        end
      else
        # next look in default directory structure
        defined_directory = default_directories.detect do |default_folder|
          folder = File.join(root, default_folder)
          next unless File.directory?(folder)
          break folder
        end
      end

      return defined_directory if File.directory?(defined_directory.to_s)

      raise Bumbleworks::InvalidSetting, "#{message} (looked in #{user_defined_directory || default_directories.join(', ')})"
    end
  end
end
