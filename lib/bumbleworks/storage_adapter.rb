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

      def new_storage(storage)
        raise UnsupportedStorage unless use?(storage)
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