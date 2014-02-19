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


    # Path to the root folder where Bumbleworks assets can be found.  By default,
    # this path will be the root returned by the detected framework (see the
    # #root method below), with "/lib/bumbleworks" appended, but you can override
    # this by defining root explicitly.
    # The definitions, tasks, and participants directories should exist here, if
    # you're using the defaults for these directories, or if they're overridden
    # with relative paths.  So in a default install, the hierarchy should look
    # like this:
    #   [defined root, or framework root]
    #     /lib
    #       /bumbleworks
    #         /participants
    #         /processes
    #         /tasks
    #
    # default: ${Framework root}/lib/bumbleworks (or no default if not in framework)
    # Exceptions: raises Bumbleworks::UndefinedSetting if no framework and not
    #   defined by the client
    #
    define_setting :root

    # Path to the folder which holds the ruote definition files. Bumbleworks
    # will load all definition files by recursively traversing the directory
    # tree under this folder. No specific loading order is guaranteed.
    # These definition files will be loaded when Bumbleworks.bootstrap! is
    # called, not Bootstrap.initialize! (since you don't want to re-register
    # the participant list every time Bumbleworks is set up, but rather as an
    # explicit task, for instance on deploy).
    #
    # default: ${Bumbleworks.root}/process_definitions then ${Bumbleworks.root}/processes
    define_setting :definitions_directory

    # Path to the folder which holds the ruote participant files. Bumbleworks
    # will recursively traverse the directory tree under this folder and ensure
    # that all found files are autoloaded before registration of participants.
    #
    # default: ${Bumbleworks.root}/participants
    define_setting :participants_directory

    # Path to the folder which holds the optional task module files, which are
    # used to dynamically extend tasks (to override methods, or implement
    # callbacks). Bumbleworks will recursively traverse the directory tree under
    # this folder and ensure that all found files are autoloaded.
    #
    # default: ${Bumbleworks.root}/tasks
    define_setting :tasks_directory

    # Path to the file in which participant registration is defined.  This file will
    # be `load`ed when Bumbleworks.bootstrap! is called, not Bootstrap.initialize!
    # (since you don't want to re-register the participant list every time Bumbleworks
    # is set up, but rather as an explicit task, for instance on deploy).
    #
    # default: ${Bumbleworks.root}/participants.rb
    define_setting :participant_registration_file

    # Bumbleworks requires a dedicated key-value storage for process information.  Three
    # storage solutions are currently supported: Hash, Redis and Sequel.  The latter
    # two require the bumbleworks-redis and bumbleworks-sequel gems, respectively.
    # You can set the storage as follows:
    #
    # @Example: Redis
    #   Bumbleworks.storage = Redis.new(:host => '127.0.0.1', :db => 0, :thread_safe => true)
    #
    # @Example: Sequel with Postgres db
    #   Bumbleworks.storage = Sequel.connect('postgres://user:password@host:port/database_name')
    #
    define_setting :storage

    # Normally, the first adapter in the storage_adapters list that can #use? the
    # configured storage will be used automatically.  This may not be what you want;
    # if you have multiple adapters that can use a Redis database or a Hash, for
    # example, you may want to specify explicitly which one to use.  Use this setting
    # to override the automatic adapter selection.
    #
    # @Example:
    #   Bumbleworks.storage_adapter = Bumbleworks::OtherHashStorage
    #
    define_setting :storage_adapter

    # This setting will be sent to the storage adapter's .new_storage method when
    # initializing the storage.  The base adapter (and the Hash adapter) ignore the
    # options argument, but for the Redis and Sequel adapters, this is a handy way
    # to pass through any options that Ruote's drivers understand.
    #
    # @Example:
    #   Bumbleworks.storage_options = { 'sequel_table_name' => 'bunnies_table' }
    #
    define_setting :storage_options

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

    # When errors occur during the execution of a process, errors are captured and dispatched to
    # the registered error handlers.  An error handler must take a single initialization argument
    # (the workitem at the point of error), and implement the #on_error method.  You can subclass the
    # Bumbleworks::ErrorHandler class for the initializer and workitem entity storage.  The default
    # handler (Bumbleworks::ErrorLogger) will simply send the configured logger an ERROR log entry.
    #
    # class MySpecialHandler < Bumbleworks::ErrorHandler
    #   def on_error
    #     p @workitem.error
    #   end
    # end
    #
    # For exclusive use:
    #   Bumbleworks.error_handlers = [MySpecialHandler, MySpecialHandler2]
    #
    # To append to exisiting handlers:
    #   Bumbleworks.error_handlers << MySpecialHandler
    #
    # default: Bumbleworks::ErrorLogger
    define_setting :error_handlers

    # If #store_history is true, all messages will be logged in the storage under a special
    # "history" key.  These messages will remain in the history even after a process has been
    # cancelled or completed, so the history can be used for auditing.
    #
    # If #store_history is false, history will be stored in-memory, but only the last 1000 messages,
    # and since this is in memory, it's useless for multiple workers in separate processes.
    #
    # Important Note:  This setting is *ignored* if the storage is a HashStorage, since having a
    # persistent storage in this case wouldn't make sense (the Hash itself being in-memory).
    #
    define_setting :store_history

    def initialize
      @storage_adapters = []
      @storage_options = {}
      @cached_paths = {}
      @timeout ||= 5
    end

    # Path where Bumbleworks will look for ruote process defintiions to load.
    # The path can be relative or absolute.  Relative paths are
    # relative to Bumbleworks.root.
    #
    def definitions_directory
      @cached_paths[:definitions_directory] ||= look_up_configured_path(
        :definitions_directory,
        :defaults => ['process_definitions', 'processes']
      )
    end

    # Path where Bumbleworks will look for ruote participants to load.
    # The path can be relative or absolute.  Relative paths are
    # relative to Bumbleworks.root.
    #
    def participants_directory
      look_up_configured_path(
        :participants_directory,
        :defaults => ['participants']
      )
    end

    # Path where Bumbleworks will look for task modules to load.
    # The path can be relative or absolute.  Relative paths are
    # relative to Bumbleworks.root.
    #
    def tasks_directory
      @cached_paths[:tasks_directory] ||= look_up_configured_path(
        :tasks_directory,
        :defaults => ['tasks']
      )
    end

    # Path where Bumbleworks will look for the participant registration
    # file. The path can be relative or absolute.  Relative paths are
    # relative to Bumbleworks.root.
    #
    def participant_registration_file
      @cached_paths[:participant_registration_file] ||= look_up_configured_path(
        :participant_registration_file,
        :defaults => ['participants.rb'],
        :file => true
      )
    end

    # Default history storage to true
    def store_history
      @store_history.nil? ? true : @store_history
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
    # frameworks (Rails, Sinatra and Rory), appending "lib/bumbleworks".
    # Otherwise, it will raise an error if not defined.
    #
    def root
      @root ||= begin
        raise UndefinedSetting.new("Bumbleworks.root must be set") unless framework_root
        File.join(framework_root, "lib", "bumbleworks")
      end
    end

    # Add a storage adapter to the set of possible adapters.  Takes an object
    # that responds to `driver`, `use?`, `storage_class`, and `display_name`.
    #
    def add_storage_adapter(adapter)
      raise ArgumentError, "#{adapter} is not a Bumbleworks storage adapter" unless
        [:driver, :use?, :new_storage, :allow_history_storage?, :storage_class, :display_name].all? { |m| adapter.respond_to?(m) }

      @storage_adapters << adapter
      @storage_adapters
    end

    # If storage_adapter is not explicitly set, find first registered adapter that
    # can use Bumbleworks.storage.
    #
    def storage_adapter
      @storage_adapter ||= begin
        all_adapters = storage_adapters
        raise UndefinedSetting, "No storage adapters configured" if all_adapters.empty?
        adapter = all_adapters.detect do |potential_adapter|
          potential_adapter.use?(storage)
        end
        raise UndefinedSetting, "Storage is missing or not supported.  Supported: #{all_adapters.map(&:display_name).join(', ')}" unless adapter
        adapter
      end
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
      @cached_paths = {}
    end

    def error_handlers
      @error_handlers ||= [Bumbleworks::ErrorLogger]
    end

  private

    def defined_settings
      self.class.defined_settings
    end

    def framework_root
      case
        when defined?(::Rails) then ::Rails.root
        when defined?(::Rory) then ::Rory.root
        when defined?(::Padrino) then ::Padrino.root
        when defined?(::Sinatra::Application) then ::Sinatra::Application.root
      end
    end

    def path_resolves?(path, options = {})
      if options[:file]
        File.file?(path.to_s)
      else
        File.directory?(path.to_s)
      end
    end

    def user_configured_path(path_type)
      user_defined_path = instance_variable_get("@#{path_type}")
      if user_defined_path
        if user_defined_path[0] == '/'
          user_defined_path
        else
          File.join(root, user_defined_path)
        end
      end
    end

    def first_existing_default_path(possible_paths, options = {})
      defaults = [possible_paths].flatten.compact.map { |d| File.join(root, d) }
      defaults.detect do |default|
        path_resolves?(default, :file => options[:file])
      end
    end

    # If the user explicitly declared a path, raises an exception if the
    # path was not found.  Missing default paths do not raise an exception
    # since no paths are required.
    def look_up_configured_path(path_type, options = {})
      return @cached_paths[path_type] if @cached_paths.has_key?(path_type)
      if user_defined_path = user_configured_path(path_type)
        if path_resolves?(user_defined_path, :file => options[:file])
          return user_defined_path
        else
          raise Bumbleworks::InvalidSetting, "#{Bumbleworks::Support.humanize(path_type)} not found (looked for #{user_defined_path || defaults.join(', ')})"
        end
      end

      first_existing_default_path(options[:defaults], :file => options[:file])
    end
  end
end
