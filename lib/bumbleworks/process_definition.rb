require "bumbleworks/tree_builder"

module Bumbleworks
  class ProcessDefinition
    class NotFound < StandardError; end
    class FileNotFound < StandardError; end
    class Invalid < StandardError; end
    class DuplicatesInDirectory < StandardError; end

    attr_reader :name, :definition, :tree

    # @public
    # Initialize a new ProcessDefinition, supplying a name (required), and
    # definition or a tree (one of which is required).  The definition should
    # be a string with a Bumbleworks.define_process block, and the tree should
    # be an actual Ruote tree.
    #
    def initialize(opts = {})
      @name = opts[:name]
      @definition = opts[:definition]
      @tree = opts[:tree]
    end

    # @public
    # Validates the ProcessDefinition by checking existence and uniqueness of
    # name, existence of one of definition or tree, and validity of definition.
    # Raises a Bumbleworks::ProcessDefinition::Invalid exception if errors are
    # found, otherwise returns true
    #
    def validate!
      errors = []
      errors << "Name must be specified" unless @name
      errors << "Definition or tree must be specified" unless @definition || @tree
      begin
        build_tree!
      rescue Invalid
        errors << "Definition is not a valid process definition"
      end
      raise Invalid, "Validation failed: #{errors.join(', ')}" unless errors.empty?
      true
    end

    # @public
    # Validates first, then adds the tree (builds it if necessary) to the
    # dashboard's variables.
    #
    def save!
      validate!
      Bumbleworks.dashboard.variables[@name] = @tree || build_tree!
      self
    end

    # @public
    # Uses the TreeBuilder to construct a tree from the given definition.
    # Captures any tree building exceptions and reraises them as
    # Bumbleworks::ProcessDefinition::Invalid exceptions.
    #
    def build_tree!
      return nil unless @definition
      @tree = Bumbleworks::TreeBuilder.new(
        :name => name, :definition => definition
      ).build!
    rescue Bumbleworks::TreeBuilder::InvalidTree => e
      raise Invalid, e.message
    end

    # @public
    # A definition can be loaded directly from a file (this is the easiest way
    # to do it, after the .create_all_from_directory! method).  Simply reads
    # the file at the given path, and set this instance's definition to the
    # contents of that file.
    #
    def load_definition_from_file(path)
      if File.exists?(path)
        @definition = File.read(path)
      else
        raise FileNotFound, "No file found at #{path}"
      end
    end

    class << self
      # @public
      # Given a key, will instantiate a new ProcessDefinition populated with the
      # tree found in the dashboard variables at that key.  If the key isn't
      # found, an exception is thrown.
      #
      def find_by_name(search_key)
        if saved_tree = Bumbleworks.dashboard.variables[search_key]
          new(:name => search_key, :tree => saved_tree)
        else
          raise NotFound, "No definition by the name of \"#{search_key}\" has been registered yet"
        end
      end

      # @public
      # This method provides a way to define a process definition directly,
      # without having to create it as a string definition or a tree.  It takes
      # a block identical to Ruote.define's block, normalizes the definition's
      # name, and `#create!`s a ProcessDefinition with the resulting tree.
      #
      def define(*args, &block)
        tree_builder = Bumbleworks::TreeBuilder.from_definition(*args, &block)
        tree_builder.build!
        create!(:tree => tree_builder.tree, :name => tree_builder.name)
      end

      # @public
      # Instantiates a new ProcessDefinition, then `#save`s it.
      #
      def create!(opts)
        pdef = new(opts)
        pdef.save!
        pdef
      end

      # @public
      # For every *.rb file in the given directory (recursive), creates a new
      # ProcessDefinition, reading the file's contents for the definition
      # string.  If the :skip_invalid option is specified, all invalid
      # definitions are skipped, and everything else is loaded.  Otherwise, the
      # first invalid definition found triggers a rollback and raises the
      # exception.
      #
      def create_all_from_directory!(directory, opts = {})
        added_names = []
        definition_files = Bumbleworks::Support.all_files(directory)
        if definition_files.values.uniq.count != definition_files.count
          raise DuplicatesInDirectory, "Definitions directory contains duplicate filenames"
        end
        definition_files.each do |path, basename|
          puts "Registering process definition #{basename} from file #{path}" if opts[:verbose] == true
          begin
            create!(:name => basename, :definition => File.read(path))
            added_names << basename
          rescue Invalid
            raise unless opts[:skip_invalid] == true
          end
        end
      rescue Invalid
        added_names.each do |name|
          Bumbleworks.dashboard.variables[name] = nil
        end
        raise
      end
    end
  end
end
