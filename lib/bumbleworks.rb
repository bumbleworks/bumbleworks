require "bumbleworks/version"
require "bumbleworks/configuration"

module Bumbleworks
  class << self
    extend Forwardable
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

    def reset!
      @configuration = nil
    end
  end
end
