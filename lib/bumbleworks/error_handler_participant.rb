module Bumbleworks
  class ErrorHandlerParticipant < ::Ruote::StorageParticipant
    def on_workitem
      return if (error_handlers = Bumbleworks.error_handlers).nil?

      error_handlers.each do |error_handler|
        error_handler.new(workitem).on_error
      end
    end
  end
end
