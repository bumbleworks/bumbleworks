class Bumbleworks::Worker < Ruote::Worker
  class Proxy
    ProxiedAttributes = [
      :id, :pid, :ip, :hostname, :system, :launched_at, :state, :name, :class, :uptime
    ]

    attr_reader *(ProxiedAttributes - [:launched_at])
    attr_reader :raw_hash

    def initialize(attributes)
      @raw_hash = attributes
      ProxiedAttributes.each do |key|
        instance_variable_set(:"@#{key}", attributes[key.to_s])
      end
    end

    # Allow storage to revert to the default for this Bumbleworks
    # instance.
    def storage
      nil
    end

    def class_name
      @class.to_s
    end

    def launched_at
      if @launched_at.is_a?(String)
        Time.parse(@launched_at)
      else
        @launched_at
      end
    end

    def ==(other)
      raw_hash == other.raw_hash
    end
  end
end