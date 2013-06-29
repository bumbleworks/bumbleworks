module Bumbleworks
  class SimpleLogger
    class << self
      def entries
        @entries ||= []
      end

      def add(level, entry)
        entries << { :level => level, :entry => entry }
      end

      def clear!
        @entries = []
      end

      [:debug, :info, :warn, :error, :fatal].each do |level|
        define_method level.to_sym do |entry|
          add level, entry
        end
      end
    end
  end
end