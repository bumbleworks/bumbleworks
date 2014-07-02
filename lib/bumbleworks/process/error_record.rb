module Bumbleworks
  class Process
    class ErrorRecord
      attr_reader :process_error

      # The initializer takes a Ruote::ProcessError instance.
      def initialize(process_error)
        @process_error = process_error
      end

      # Replays the error's process at the point where the error occurred.
      # Should only be called when the cause of the error has been fixed,
      # since otherwise this will just cause the error to show up again.
      def replay
        Bumbleworks.dashboard.replay_at_error(@process_error)
      end

      # Returns the workitem at the position where this error occurred.
      def workitem
        @process_error.workitem
      end

      # Returns the FlowExpressionId of the expression where this error
      # occurred.
      def fei
        @process_error.fei
      end

      # Returns the class name of the error that was actually raised
      # during execution of the process.

      # Be aware that this class may not exist in the current binding
      # when you instantiate the ErrorRecord; if it does not, calling
      # #reify will throw an exception.
      def error_class_name
        @process_error.h['class']
      end

      # Returns the original error's backtrace.
      #
      # The original backtrace will be returned in standard backtrace
      # format: an array of strings with paths and line numbers.
      def backtrace
        @process_error.h['trace'].split(/\n/)
      end

      # Returns the original error message.
      #
      # Ruote's error logging has a strange issue; the message recorded
      # and returned via the Ruote::ProcessError instance is the full
      # #inspect of the error.  This method strips away the resulting
      # cruft (if it exists) and leaves behind just the message itself.
      def message
        @message ||= @process_error.message.
          gsub(/\#\<#{error_class_name}: (.*)\>$/, '\1')
      end

      # Re-instantiates the original exception.
      #
      # If you wish to re-create the actual exception that was raised
      # during process execution, this method will attempt to return
      # an instance of the error class, with the message and backtrace
      # restored.
      #
      # In order for this to work, the error class itself must be a
      # defined constant in the current binding; if it's not, you'll get
      # an exception.  Be cognizant of this caveat if you choose to use
      # this feature; Bumbleworks makes no attempt to protect you.
      #
      # This is not because Bumbleworks doesn't love you.  It just wants
      # you to spread your wings, and the only way to truly experience
      # flight is to first taste the ground.
      def reify
        klass = Bumbleworks::Support.constantize(error_class_name)
        err = klass.new(message)
        err.set_backtrace(backtrace)
        err
      end
    end
  end
end