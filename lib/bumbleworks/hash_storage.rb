require 'bumbleworks/storage_adapter'

module Bumbleworks
  class HashStorage < Bumbleworks::StorageAdapter
    class << self
      def driver
        ::Ruote::HashStorage
      end

      def storage_class
        Hash
      end

      def allow_history_storage?
        false
      end
    end
  end
end