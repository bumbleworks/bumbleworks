require "bumbleworks/version"
require "bumbleworks/configuration"
require "bumbleworks/support"
require "bumbleworks/process_definition"
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

    Configuration.defined_settings.each do |setting|
      def_delegators :configuration, setting, "#{setting.to_s}="
    end

    def configure
      reset!
      yield configuration if block_given?
    end

    def configuration
      @configuration ||= Bumbleworks::Configuration.new
    end

    def register_participants(&block)
      @participant_block = block
    end

    def participant_block
      raise UnsupportedMode unless @env == 'test'
      @participant_block
    end

    def start!(options = {:autostart_worker => true})
      load_participants
      register_participant_list
      load_process_definitions
      register_process_definitions
    end

    def engine
      @engine ||= Ruote::Dashboard.new(ruote_storage)
    end

    def define_process(name, *args, &block)
      if registered_process_definitions[name]
        raise DefinitionDuplicate, "the process '#{name}' has already been defined"
      end

      registered_process_definitions[name] = ProcessDefinition.define_process(name, *args, &block)
    end

    def reset!
      @configuration = nil
      @participant_block = nil
      shutdown_engine
    end

    private
    # managing participants
    def register_participant_list
      if @participant_block.is_a? Proc
        engine.register &@participant_block
      end

      unless engine.participant_list.any? {|pl| pl.regex == "^.+$"}
        catchall = Ruote::ParticipantEntry.new(["^.+$", ["Ruote::StorageParticipant", {}]])
        engine.participant_list = engine.participant_list.push(catchall)
      end
    end

    def load_participants
      all_files(participants_directory) do |name, path|
        Object.autoload name.to_sym, path
      end
    end

    # managing process definition
    def load_process_definitions
      all_files(definitions_directory) do |_, path|
        ProcessDefinition.create!(path)
      end
    end

    def registered_process_definitions
      @registered_process_definitions ||= {}
    end

    def register_process_definitions
      registered_process_definitions.each do |name,process_definition|
        engine.variables[name] = process_definition
      end
    end

    def clear_process_definitons
      registered_process_definitions.keys.each do |k|
        engine.variables[name] = nil
      end
      @registered_process_definitions = nil
    rescue UndefinedSetting  # storage might not be setup yet
    end

    def all_files(directory)
      Dir["#{directory}/**/*.rb"].each do |path|
        name = File.basename(path, '.rb')
        name = Bumbleworks::Support.camelize(name)
        yield name, path
      end
    end

    # managing ruote
    def ruote_storage
      raise UndefinedSetting, "Storage must be set" unless storage

      case storage.class.name
        when /^Redis/  then Ruote::Redis::Storage.new(storage)
        when /^Hash/   then Ruote::HashStorage.new(storage)
        when /^Sequel/ then Ruote::Sequel::Storage.new(storage)
      end
    end

    def shutdown_engine
      clear_process_definitons
      @engine.shutdown if @engine && @engine.respond_to?(:shutdown)
      @engine = nil
    end
  end
end
