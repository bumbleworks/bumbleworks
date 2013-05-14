require 'bumbleworks/storage_adapter'

module Bumbleworks
  class HashStorage < Bumbleworks::StorageAdapter
    def self.driver
      ::Ruote::HashStorage
    end

    def self.display_name
      'Hash'
    end
  end
end