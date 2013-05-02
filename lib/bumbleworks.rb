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

    private
    def reset!
      @configuration = nil
      @participant_block = nil
    end

    end
  end
end
