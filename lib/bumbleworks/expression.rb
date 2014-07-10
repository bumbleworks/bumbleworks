module Bumbleworks
  class Expression
    attr_reader :expid, :fei

    class << self
      def from_fei(fei)
        fexp = ::Ruote::Exp::FlowExpression.fetch(Bumbleworks.dashboard.context, fei)
        new(fexp)
      end
    end

    def initialize(flow_expression)
      @flow_expression = flow_expression
      @fei = @flow_expression.fei
      @expid = @fei.expid
    end

    def ==(other)
      @fei = other.fei
    end

    # Returns a Bumbleworks::Process instance for the expression's
    # wfid; effectively, the process instance this expression is
    # a part of.
    def process
      @process ||= Bumbleworks::Process.new(@fei.wfid)
    end

    # Returns the process tree at this expression.
    def tree
      @flow_expression.tree
    end

    # Returns a Bumbleworks::Process::ErrorRecord instance for the
    # expression's error, if there is one.  If no error was raised
    # during the execution of this expression, returns nil.
    #
    # Note that what is returned is not the exception itself that
    # was raised during execution, but rather a *record* of that error.
    # If you want a re-created instance of the actual exception,
    # you can call #reify on the ErrorRecord instance returned.
    def error
      @error ||= ruote_error
    end

    # Cancel this expression.  The process will then move on to the
    # next expression.
    def cancel!
      Bumbleworks.dashboard.cancel_expression(@fei)
    end

    # Kill this expression.  The process will then move on to the
    # next expression.
    #
    # WARNING: Killing an expression will not trigger any 'on_cancel'
    # callbacks.  It's preferable to #cancel! the expression if you
    # can.
    def kill!
      Bumbleworks.dashboard.kill_expression(@fei)
    end

    # Returns the workitem as it was applied to this expression.
    def workitem
      Workitem.new(@flow_expression.applied_workitem)
    end

  private

    def ruote_error
      process.errors.detect { |err| err.fei == @fei }
    end
  end
end