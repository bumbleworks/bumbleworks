module Bumbleworks
  class StorageAdapter
    class << self
      attr_accessor :auto_register

      def auto_register?
        auto_register.nil? || auto_register == true
      end

      def driver
        raise "Subclass responsibility"
      end

      def use?(storage)
        storage.class.name =~ /^#{display_name}/
      end

      def display_name
        raise "Subclass responsibility"
      end
    end
  end
end