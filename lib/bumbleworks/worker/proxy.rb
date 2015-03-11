class Bumbleworks::Worker < Ruote::Worker
  class Proxy
    ProxiedAttributes = [
      :id, :pid, :ip, :hostname, :system, :launched_at, :state, :name, :class
    ]

    attr_reader *(ProxiedAttributes - [:launched_at])
    attr_reader :raw_hash

    def initialize(attributes)
      @raw_hash = attributes
      ProxiedAttributes.each do |key|
        instance_variable_set(:"@#{key}", attributes[key.to_s])
      end
    end

    def launched_at
      Time.parse(@launched_at)
    end

    def ==(other)
      raw_hash == other.raw_hash
    end
  end
end