require 'securerandom'
require_relative "worker/info"

class Bumbleworks::Worker < Ruote::Worker
  class WorkerStateNotChanged < StandardError; end

  attr_reader :id, :pid, :ip, :hostname, :system, :launched_at

  class << self
    def info
      Bumbleworks.dashboard.worker_info || {}
    end

    def shutdown_all(options = {})
      # First, send all running workers a message to stop
      change_worker_state('stopped', options)
      # Now ensure that future started workers will be started
      # in "running" mode instead of automatically stopped
      change_worker_state('running', options)
    end

    def pause_all(options = {})
      change_worker_state('paused', options)
    end

    def unpause_all(options = {})
      change_worker_state('running', options)
    end

    def worker_states
      info.inject({}) { |hsh, info|
        id, state = info[0], info[1]['state']
        if state && state != 'stopped'
          hsh[id] = state
        end
        hsh
      }
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
            worker_info['state'] == 'stopped' ||
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
    @pid = Process.pid
    @id = SecureRandom.uuid
    @launched_at = Time.now

    @ip = Ruote.local_ip
    @hostname = Socket.gethostname
    @system = `uname -a`.strip rescue nil

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
end