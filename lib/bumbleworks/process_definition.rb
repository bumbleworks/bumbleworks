module Bumbleworks
  class DefinitionNotFound < StandardError; end
  class DefinitionFileNotFound < StandardError; end
  class DefinitionInvalid < StandardError; end
  class DefinitionDuplicate < StandardError; end

  class ProcessDefinition
    attr_accessor :definition

    class << self
      def define_process(name, *args, &block)
        args.unshift({:name => name})
        Ruote.define *args, &block
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
