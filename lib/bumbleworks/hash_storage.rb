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
    end
  end
end