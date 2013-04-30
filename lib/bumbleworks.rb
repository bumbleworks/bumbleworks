require "bumbleworks/version"
require "bumbleworks/configuration"

module Bumbleworks
  class << self
    extend Forwardable
    def_delegators :@configuration, :root, :definitions_directory, :participants_directory

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
