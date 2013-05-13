module Bumbleworks
  # Support methods for utility functionality such as string modification -
  # could also be accomplished by monkey-patching String class.
  module Support
    module_function

    def camelize(string)
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
      string = string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
    end

    def all_files(directory, options = {})
      Dir["#{directory}/**/*.rb"].each do |path|
        name = File.basename(path, '.rb')
        name = camelize(name) if options[:camelize] == true
        yield path, name
      end
    end
  end
end
