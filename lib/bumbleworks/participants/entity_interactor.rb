module Bumbleworks
  class EntityInteractor < Bumbleworks::Participant
    def on_workitem
      method_name = workitem.fields['params']['method'] ||
        workitem.fields['params']['to'] ||
        workitem.fields['params']['for']
      result_field = workitem.fields['params']['and_save_as']
      arguments = workitem.fields['params']['arguments'] ||
        workitem.fields['params']['with']
      result = call_method(method_name, :save_as => result_field, :args => arguments)
      reply
    end

    def call_method(method_name, options = {})
      result = if options[:args]
        options[:args] = [options[:args]] if options[:args].is_a?(Hash)
        entity.send(method_name, *options[:args])
      else
        entity.send(method_name)
      end
      if result && options[:save_as]
        workitem.fields[options[:save_as]] = result
      end
      result
    end
  end
end
