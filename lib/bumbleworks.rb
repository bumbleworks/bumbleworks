require "bumbleworks/version"
require "bumbleworks/configuration"
require "ruote"
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
      load_and_register_participants
    end

    def engine
      @engine ||= Ruote::Dashboard.new(ruote_storage)
    end

    def reset!
      @configuration = nil
      @participant_block = nil
      shutdown_engine
    end

    private
    def load_and_register_participants
      if @participant_block.is_a? Proc
        engine.register &@participant_block
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
