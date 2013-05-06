module Bumbleworks
  class DefinitionNotFound < StandardError; end
  class DefinitionFileNotFound < StandardError; end
  class DefinitionInvalid < StandardError; end
  class DefinitionDuplicate < StandardError; end

  class ProcessDefinition
    attr_accessor :definition

    class << self
      def define_process(name, *args, &block)
        if Bumbleworks.engine.variables[name]
          raise DefinitionDuplicate, "the process '#{name}' has already been defined"
        end

        args.unshift({:name => name})
        pdef = Ruote.define *args, &block
        Bumbleworks.engine.variables[name] = pdef
      end

      def create!(filename = nil)
        if File.exists?(filename.to_s)
          load filename
        else
          raise DefinitionFileNotFound, "Could not find definition file: #{filename}"
        end
      end
    end

  end
end
