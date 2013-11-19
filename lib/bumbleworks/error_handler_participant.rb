module Bumbleworks
  class ErrorHandlerParticipant
    include ::Ruote::LocalParticipant

    def on_workitem
      return if (error_handlers = Bumbleworks.error_handlers).empty?

      error_handlers.each do |error_handler|
        error_handler.new(workitem).on_error
      end
    end
  end
end
