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
      Dir["#{directory}/**/*.rb"].inject({}) do |memo, path|
        name = File.basename(path, '.rb')
        name = camelize(name) if options[:camelize] == true
        memo[path] = name
        memo
      end
    end

    def constantize(name)
      name_parts = name.split('::')
      name_parts.shift if name_parts.first.empty?
      constant = Object

      name_parts.each do |name_part|
        constant_defined = if Module.method(:const_defined?).arity == 1
          constant.const_defined?(name_part)
        else
          constant.const_defined?(name_part, false)
        end
        constant = constant_defined ? constant.const_get(name_part) : constant.const_missing(name_part)
      end
      constant
    end
  end
end
