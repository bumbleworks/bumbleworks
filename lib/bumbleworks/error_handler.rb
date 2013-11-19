module Bumbleworks
  class ErrorHandler
    include WorkitemEntityStorage
    class SubclassResponsibility < StandardError; end

    attr_accessor :workitem
    def initialize(workitem)
      @workitem = workitem
    end

    def on_error
      raise SubclassResponsibility
    end
  end
end
