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
    end

    def engine
      @engine ||= Ruote::Dashboard.new(ruote_storage)
    end

    def define(name, *args, &block)
      ProcessDefinition.define(name, *args, &block)
    end

    def reset!
      @configuration = nil
      @participant_block = nil
      shutdown_engine
    end

    private
    def register_participant_list
      if @participant_block.is_a? Proc
        engine.register &@participant_block
      end
    end

    def load_participants
      all_files(participants_directory) do |name, path|
        Object.autoload name.to_sym, path
      end
    end

    def load_process_definitions
      all_files(definitions_directory) do |_, path|
        ProcessDefinition.create!(path)
      end
    end

    def all_files(directory)
      Dir["#{directory}/**/*.rb"].each do |path|
        name = File.basename(path, '.rb')
        name = Bumbleworks::Support.camelize(name)
        yield name, path
      end
    end

    def ruote_storage
      raise UndefinedSetting, "Storage must be set" unless storage

      case storage
        when Redis then Ruote::Redis::Storage.new(storage)
        when Hash then Ruote::HashStorage.new(storage)
      end
    end

    def shutdown_engine
      @engine.shutdown if @engine && @engine.respond_to?(:shutdown)
      @engine = nil
    end

  end
end
