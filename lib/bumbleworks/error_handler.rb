module Bumbleworks
  class ErrorHandler
    include WorkitemEntityStorage

    attr_accessor :workitem
    def initialize(workitem)
      self.workitem = workitem
    end

    def on_error
      return unless logger
      logger.error(
        :actor => workitem.wf_name,
        :action => 'process error',
        :target_type => entity_fields[:type],
        :target_id => entity_fields[:identifier],
        :metadata => metadata
      )
    end

    private
    def logger
      Bumbleworks.logger
    end

    def metadata
      {
        :wfid => workitem.wfid,
        :error => workitem.error,
      }
    end
  end
end
