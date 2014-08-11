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
      options[:timeout] ||= Bumbleworks.timeout
      with_worker_state_enabled do
        Bumbleworks.dashboard.worker_state = new_state
        start_time = Time.now
        until worker_states.values.all? { |state| state == new_state }
          if (Time.now - start_time) > options[:timeout]
            raise WorkerStateNotChanged, "Worker states: #{worker_states.inspect}"
          end
          sleep 0.1
        end
      end
      return true
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
    @info.save_with_cleanup if @info
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

  class Info < Ruote::Worker::Info
    def <<(msg)
      last_save = @last_save
      super
      cleanup_saved_info if Time.now > last_save + 60
    end

    def save_with_cleanup
      save
      cleanup_saved_info
    end

    def cleanup_saved_info
      key = [@worker.name, @ip.gsub(/\./, '_'), $$.to_s].join('/')
      doc = @worker.storage.get('variables', 'workers')
      existing_worker_info = doc['workers'].delete(key)
      if existing_worker_info
        doc['workers'][@worker.id] = existing_worker_info.merge({
          'state' => @worker.state,
          'name' => @worker.name
        })
        result = @worker.storage.put(doc)
        # result will be nil if put succeeded; if it's not,
        # let's try again
        cleanup_saved_info if result
      else
        cleanup_saved_info
      end
    end
  end
end