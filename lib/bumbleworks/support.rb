module Bumbleworks
  # Support methods for utility functionality such as string modification -
  # could also be accomplished by monkey-patching String class.
  module Support
    module_function
    class WaitTimeout < StandardError; end

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
        const_defined_args = [name_part]
        const_defined_args << false unless Module.method(:const_defined?).arity == 1
        constant_defined = constant.const_defined?(*const_defined_args)
        constant = constant_defined ? constant.const_get(name_part) : constant.const_missing(name_part)
      end
      constant
    end

    def tokenize(string)
      return nil if string.nil?
      string = string.to_s.gsub(/&/, ' and ').
        gsub(/[ \/]+/, '_').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        downcase
    end

    def humanize(string)
      return nil if string.nil?
      tokenize(string).gsub(/_/, ' ').
        gsub(/^\w/) { $&.upcase }
    end

    def titleize(string)
      return nil if string.nil?
      humanize(string).gsub(/\b('?[a-z])/) { $1.capitalize }
    end

    def wait_until(options = {}, &block)
      options[:timeout] ||= Bumbleworks.timeout
      start_time = Time.now
      until block.call
        if (Time.now - start_time) > options[:timeout]
          raise WaitTimeout
        end
        sleep 0.1
      end
    end
  end
end
