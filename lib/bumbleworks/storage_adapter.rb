module Bumbleworks
  class StorageAdapter
    class UnsupportedStorage < StandardError; end
    class << self
      attr_accessor :auto_register

      def auto_register?
        auto_register.nil? || auto_register == true
      end

      def driver
        raise "Subclass responsibility"
      end

      def new_storage(storage, options = {})
        raise UnsupportedStorage unless use?(storage)
        wrap_storage_with_driver(storage, options)
      end

      def wrap_storage_with_driver(storage, options = {})
        # the base method ignores options; use them in subclasses
        driver.new(storage)
      end

      def use?(storage)
        storage.is_a? storage_class
      end

      def storage_class
        raise "Subclass responsibility"
      end

      def display_name
        storage_class.name
      end

      def allow_history_storage?
        true
      end
    end
  end
end