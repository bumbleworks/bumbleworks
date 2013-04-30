module Bumbleworks
  # Stores configruation information
  #
  # Configruation inforamtion is loaded from a configuration block defined within
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
    class UndefinedSetting < StandardError; end

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
    # default: non, must be specified
    # Exceptions: raises Bumbleworks::UndefinedSetting if not defined by the client
    #
    define_setting :root

    # Path to the folder which holds the ruote definition files. Bumbleworks
    # will load all definition files by recursively traversing the directory
    # tree under this folder. No specific loading order is guranteed
    #
    # default: ${Bumbleworks.root}/lib/process_definitions
    define_setting :definitions_directory

    def initialize
      @defined_settings = []
    end


    def definitions_directory
      @definitions_directory ||= File.join(root, default_folder)
    end

    def root
      raise UndefinedSetting.new("Bumbleworks.root must be set") unless @root
      @root
    end

    def clear!
      defined_settings.each {|setting| instance_variable_set("@#{setting}", nil)}
    end

    private
    def defined_settings
      self.class.defined_settings
    end

    def default_folder
      '/lib/process_definitions'
    end
  end
end
