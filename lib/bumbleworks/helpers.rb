require "bumbleworks/helpers/ruote"
require "bumbleworks/helpers/participant"
require "bumbleworks/helpers/definition"

module Bumbleworks
  module Helpers
    def self.included(base)
      base.class_eval do
        include Helpers::Ruote
        include Helpers::Participant
        include Helpers::Definition
      end
    end

    def configuration
      @configuration ||= Bumbleworks::Configuration.new
    end

    def reset!
      @configuration = nil
      @participant_block = nil
      shutdown_dashboard
    end
  end
end
