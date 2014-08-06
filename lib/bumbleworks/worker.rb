require 'securerandom'

class Bumbleworks::Worker < Ruote::Worker
  class WorkersCannotBeStopped < StandardError; end

  attr_reader :id

  class << self
    def stop_all(options = {})
      options[:timeout] ||= Bumbleworks.timeout

      with_worker_state_enabled do
        Bumbleworks.dashboard.worker_state = 'stopped'
        start_time = Time.now
        until worker_states.values.all? { |state| state == 'stopped' }
          if (Time.now - start_time) > options[:timeout]
            raise WorkersCannotBeStopped, "Worker states: #{worker_states.inspect}"
          end
          sleep 0.1
        end
      end
    end

    def worker_states
      Bumbleworks.dashboard.worker_info.inject({}) { |hsh, info|
        hsh[info[0]] = info[1]['state']
        hsh
      }
    end

    def with_worker_state_enabled
      Bumbleworks.dashboard.context['worker_state_enabled'] = true
      yield
      Bumbleworks.dashboard.context['worker_state_enabled'] = false
    end
  end

  def initialize(*args, &block)
    super
    @id = SecureRandom.uuid
    @info = @info && Info.new(self)
    @info.save
  end

  def run
    super
    @info.save
  end

  class Info < Ruote::Worker::Info
    def save
      super
      key = [@worker.name, @ip.gsub(/\./, '_'), $$.to_s].join('/')
      doc = @worker.storage.get('variables', 'workers')
      doc['workers'][@worker.id] = doc['workers'].delete(key).merge({
        'state' => @worker.state,
        'name' => @worker.name
      })
      @worker.storage.put(doc)
    end
  end
end