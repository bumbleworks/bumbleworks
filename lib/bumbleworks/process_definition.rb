module Bumbleworks
  class DefinitionNotFound < StandardError; end
  class DefinitionFileNotFound < StandardError; end
  class DefinitionInvalid < StandardError; end

  class ProcessDefinition
    attr_accessor :definition, :filename

    def self.create!(filename)
      pdef = new(filename)
      pdef.load_definition_from_file
      pdef
    end

    def initialize(filename)
      @filename = filename
    end

    def validate!
      errors = []
      errors << "definition" unless @definition
      raise DefinitionInvalid, "Process definition must have a #{errors.join(" and ")}" if errors.present?
      true
    end

    def load_definition_from_file
      if File.exists?(filename.to_s)
        @definition = Ruote::Reader.read(filename)
      else
        raise DefinitionFileNotFound, "Could not find definition file: #{filename}"
      end
    end

  end
end
