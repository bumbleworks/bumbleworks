require "bumbleworks/version"
require "bumbleworks/configuration"

module Bumbleworks
  class << self
    def configure
      yield configuration if block_given?
    end

    def configuration
      @configuration ||= Bumbleworks::Configuration.new
    end
  end
end
