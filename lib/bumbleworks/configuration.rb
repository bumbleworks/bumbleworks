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
    class InvalidSetting < StandardError; end

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
    # will autoload all definition files by recursively traversing the directory
    # tree under this folder. No specific loading order is guranteed
    #
    # default: ${Bumbleworks.root}/lib/process_definitions
    define_setting :definitions_directory

    # Path to the folder which holds the ruote participant files. Bumbleworks
    # will autoload all participant files by recursively traversing the directory
    # tree under this folder. No specific loading order is guranteed
    #
    # Bumbleworks will guarantee that these files are autoloaded before registration
    # of participants.
    #
    # default: ${Bumbleworks.root}/participants then ${Bumbleworks.root}/app/participants
    define_setting :participants_directory

    def initialize
      @defined_settings = []
    end

    def definitions_directory
      @definitions_folder ||= default_definition_directory
    end

    def participants_directory
      @participants_folder ||= default_participant_directory
    end

    def root
      @root ||= case
      when defined?(Rails) then Rails.root
      when defined?(Rory) then Rory.root
      when defined?(Sinatra::Application) then Sinatra::Application.root
      else
        raise UndefinedSetting.new("Bumbleworks.root must be set") unless @root
      end
    end

    def clear!
      defined_settings.each {|setting| instance_variable_set("@#{setting}", nil)}
      @definitions_folder = @participants_folder = nil
    end

    private
    def defined_settings
      self.class.defined_settings
    end

    def default_definition_directory
      default_folders = ['lib/process_definitions']
      find_folder(default_folders, @definitions_directory, "Definitions folder not found")
    end

    def default_participant_directory
      default_folders = ['participants', 'app/participants']
      find_folder(default_folders, @participants_directory, "Participants folder not found")
    end

    def find_folder(default_directories, defined_directory, message)
      # use defined directory structure if defined
      if defined_directory
        defined_directory = File.join(root, defined_directory) unless defined_directory[0] == '/'
      end

      # next look in default directory structure
      defined_directory ||= default_directories.detect do |default_folder|
        folder = File.join(root, default_folder)
        next unless File.directory?(folder)
        break folder
      end

      return defined_directory if File.directory?(defined_directory.to_s)

      raise Bumbleworks::Configuration::InvalidSetting, "#{message}: #{defined_directory}"
    end
  end
end
