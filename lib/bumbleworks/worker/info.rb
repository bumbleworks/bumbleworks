require_relative "proxy"

class Bumbleworks::Worker < Ruote::Worker
  class Info < Ruote::Worker::Info
    attr_reader :worker
    extend Forwardable
    extend Enumerable

    def_delegators :worker,
      :id, :pid, :name, :state, :ip, :hostname, :system, :launched_at

    class << self
      def raw_hash
        Bumbleworks.dashboard.worker_info || {}
      end

      def each
        raw_hash.each { |k, v|
          yield from_hash(v.merge('id' => k))
        }
      end

      def all
        to_a
      end

      def where(options)
        filter_proc = proc { |worker|
          options.all? { |k, v|
            worker.send(k.to_sym) == v
          }
        }
        filter(&filter_proc)
      end

      def filter
        return [] unless block_given?
        select { |info| yield info.worker }
      end

      def [](worker_id)
        from_hash(raw_hash[worker_id].merge('id' => worker_id))
      end

      def from_hash(hash)
        new(Bumbleworks::Worker::Proxy.new(hash))
      end

      def forget_worker(id_to_delete)
        purge_worker_info do |id, info|
          id == id_to_delete
        end
      end

      def purge_stale_worker_info
        purge_worker_info do |id, info|
          info['state'].nil? || info['state'] == 'stopped'
        end
      end

      def purge_worker_info(&block)
        doc = Bumbleworks.dashboard.storage.get('variables', 'workers')
        return unless doc
        doc['workers'] = doc['workers'].reject { |id, info|
          block.call(id, info)
        }
        result = Bumbleworks.dashboard.storage.put(doc)
        purge_stale_worker_info if result
        all
      end
    end

    def ==(other)
      other.is_a?(Bumbleworks::Worker::Info) &&
        other.worker == worker
    end

    def raw_hash
      self.class.raw_hash[worker.id]
    end

    def worker_class_name
      worker.class_name
    end

    def uptime
      if in_stopped_state? && worker.respond_to?(:uptime)
        worker.uptime
      else
        Time.now - worker.launched_at
      end
    end

    def in_stopped_state?
      ["stopped"].include?(worker.state)
    end

    def updated_at
      Time.parse(raw_hash['put_at'])
    end

    def updated_since?(latest_time)
      updated_at >= latest_time
    end

    def updated_recently?(options = {})
      options[:seconds_ago] ||= Bumbleworks.timeout
      latest_time = Time.now - options[:seconds_ago]
      updated_since?(latest_time)
    end

    def responding?(options = {})
      options[:since] ||= Time.now - Bumbleworks.timeout
      Bumbleworks::Worker.with_worker_state_enabled do
        Bumbleworks::Support.wait_until(options) do
          updated_since?(options[:since])
        end
      end
      true
    rescue Bumbleworks::Support::WaitTimeout
      false
    end

    def stalling?
      !responding?
    end

    def storage
      @worker.storage || Bumbleworks.dashboard.storage
    end

    def initialize(worker)
      @worker = worker
      @last_save = Time.now - 2 * 60

      @msgs = [] unless worker.is_a?(Bumbleworks::Worker::Proxy)
    end

    def worker_info_document
      doc = storage.get('variables', 'workers') || {}

      doc['type'] = 'variables'
      doc['_id'] = 'workers'
      doc['workers'] ||= {}
      doc
    end

    def processed_last_minute
      raw_hash["processed_last_minute"]
    end

    def wait_time_last_minute
      raw_hash["wait_time_last_minute"]
    end

    def processed_last_hour
      raw_hash["processed_last_hour"]
    end

    def wait_time_last_hour
      raw_hash["wait_time_last_hour"]
    end

    def constant_worker_info_hash
      {
        "id" => @worker.id,
        "class" => @worker.class_name,
        "name" => @worker.name,
        "ip" => @worker.ip,
        "hostname" => @worker.hostname,
        "pid" => @worker.pid,
        "system" => @worker.system,
        "launched_at" => @worker.launched_at,
        "state" => @worker.state
      }
    end

    def save
      doc = worker_info_document

      worker_info_hash = doc['workers'][@worker.id] || {}

      worker_info_hash.merge!(constant_worker_info_hash)
      worker_info_hash.merge!({
        'put_at' => Ruote.now_to_utc_s,
        'uptime' => uptime,
      })

      if defined?(@msgs)
        now = Time.now

        @msgs = @msgs.drop_while { |msg|
          Time.parse(msg['processed_at']) < now - 3600
        }
        mm = @msgs.drop_while { |msg|
          Time.parse(msg['processed_at']) < now - 60
        }

        hour_count = @msgs.size < 1 ? 1 : @msgs.size
        minute_count = mm.size < 1 ? 1 : mm.size

        worker_info_hash.merge!({
          'processed_last_minute' =>
            mm.size,
          'wait_time_last_minute' =>
            mm.inject(0.0) { |s, m| s + m['wait_time'] } / minute_count.to_f,
          'processed_last_hour' =>
            @msgs.size,
          'wait_time_last_hour' =>
            @msgs.inject(0.0) { |s, m| s + m['wait_time'] } / hour_count.to_f
        })
      end

      doc['workers'][@worker.id] = worker_info_hash

      r = storage.put(doc)

      @last_save = Time.now

      save if r != nil
    end
  end
end