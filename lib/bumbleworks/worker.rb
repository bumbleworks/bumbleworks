require 'securerandom'

class Bumbleworks::Worker < Ruote::Worker
  class WorkerStateNotChanged < StandardError; end

  attr_reader :id

  class << self
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
        hsh[info[0]] = info[1]['state']
        hsh
      }
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
    @info.save_with_cleanup
  end

  def determine_state
    if @context['worker_state_enabled']
      super
      @info.save_with_cleanup
    end
  end

  class Info < Ruote::Worker::Info
    def <<(msg)
      super
      cleanup_saved_info if Time.now > @last_save + 60
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