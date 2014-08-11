require 'securerandom'

class Bumbleworks::Worker < Ruote::Worker
  class WorkerStateNotChanged < StandardError; end

  attr_reader :id

  class << self
    def info
      Bumbleworks.dashboard.worker_info
    end

    def shutdown_all(options = {})
      change_worker_state('stopped', options)
    end

    def pause_all(options = {})
      change_worker_state('paused', options)
    end

    def unpause_all(options = {})
      change_worker_state('running', options)
    end

    def worker_states
      Bumbleworks.dashboard.worker_info.inject({}) { |hsh, info|
        id, state = info[0], info[1]['state']
        if state && state != 'stopped'
          hsh[id] = state
        end
        hsh
      }
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
      doc['workers'] = doc['workers'].reject { |id, info|
        block.call(id, info)
      }
      result = Bumbleworks.dashboard.storage.put(doc)
      purge_stale_worker_info if result
      info
    end

    def change_worker_state(new_state, options = {})
      with_worker_state_enabled do
        Bumbleworks.dashboard.worker_state = new_state
        Bumbleworks::Support.wait_until(options) do
          worker_states.values.all? { |state| state == new_state }
        end
      end
      return true
    rescue Bumbleworks::Support::WaitTimeout
      raise WorkerStateNotChanged, "Worker states: #{worker_states.inspect}"
    end

    def refresh_worker_info(options = {})
      with_worker_state_enabled do
        Bumbleworks::Support.wait_until(options) do
          info.all? { |id, worker_info|
            Time.parse(worker_info['put_at']) > Time.now - 1
          }
        end
      end
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
    if @info
      @info = Info.new(self)
      save_info
    end
  end

  def save_info
    @info.save if @info
  end

  def shutdown
    super
    save_info
  end

  def determine_state
    if @context['worker_state_enabled']
      super
      save_info
    end
  end

  def info
    self.class.info[id]
  end

  class Info < Ruote::Worker::Info
    def save
      doc = @worker.storage.get('variables', 'workers') || {}

      doc['type'] = 'variables'
      doc['_id'] = 'workers'

      now = Time.now

      @msgs = @msgs.drop_while { |msg|
        Time.parse(msg['processed_at']) < now - 3600
      }
      mm = @msgs.drop_while { |msg|
        Time.parse(msg['processed_at']) < now - 60
      }

      hour_count = @msgs.size < 1 ? 1 : @msgs.size
      minute_count = mm.size < 1 ? 1 : mm.size

      (doc['workers'] ||= {})[@worker.id] = {

        'class' => @worker.class.to_s,
        'name' => @worker.name,
        'ip' => @ip,
        'hostname' => @hostname,
        'pid' => $$,
        'system' => @system,
        'put_at' => Ruote.now_to_utc_s,
        'uptime' => Time.now - @since,
        'state' => @worker.state,

        'processed_last_minute' =>
          mm.size,
        'wait_time_last_minute' =>
          mm.inject(0.0) { |s, m| s + m['wait_time'] } / minute_count.to_f,
        'processed_last_hour' =>
          @msgs.size,
        'wait_time_last_hour' =>
          @msgs.inject(0.0) { |s, m| s + m['wait_time'] } / hour_count.to_f
      }

      r = @worker.storage.put(doc)

      @last_save = Time.now

      save if r != nil
    end
  end
end