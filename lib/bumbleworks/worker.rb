require 'securerandom'
require_relative "worker/info"

class Bumbleworks::Worker < Ruote::Worker
  class WorkerStateNotChanged < StandardError; end

  attr_reader :id, :pid, :ip, :hostname, :system, :launched_at

  class << self
    def info
      Bumbleworks::Worker::Info || {}
    end

    def shutdown_all(options = {})
      # First, send all running workers a message to stop
      change_worker_state('stopped', options)
    ensure
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

    def active_worker_states
      info.inject({}) { |hsh, info|
        id, state = info.id, info.state
        unless info.in_stopped_state?
          hsh[id] = state
        end
        hsh
      }
    end

    def change_worker_state(new_state, options = {})
      with_worker_state_enabled do
        Bumbleworks.dashboard.worker_state = new_state
        Bumbleworks::Support.wait_until(options) do
          active_worker_states.values.all? { |state| state == new_state }
        end
      end
      return true
    rescue Bumbleworks::Support::WaitTimeout
      raise WorkerStateNotChanged, "Worker states: #{active_worker_states.inspect}"
    end

    def refresh_worker_info(options = {})
      with_worker_state_enabled do
        info.each do |worker_info|
          if !worker_info.in_stopped_state? && worker_info.stalling?
            worker_info.record_new_state("stalled")
          end
        end
      end
    end

    def toggle_worker_state_enabled(switch)
      unless [true, false].include?(switch)
        raise ArgumentError, "Must call with true or false"
      end
      Bumbleworks.dashboard.context['worker_state_enabled'] = switch
    end

    def worker_state_enabled?
      !!Bumbleworks.dashboard.context['worker_state_enabled']
    end

    def with_worker_state_enabled
      was_already_enabled = worker_state_enabled?
      toggle_worker_state_enabled(true) unless was_already_enabled
      yield
    ensure
      toggle_worker_state_enabled(false) unless was_already_enabled
    end

    def control_document
      doc = Bumbleworks.dashboard.storage.get('variables', 'worker_control') || {}
      doc['type'] = 'variables'
      doc['_id'] = 'worker_control'
      doc['workers'] ||= {}
      doc
    end

    def info_document
      doc = Bumbleworks.dashboard.storage.get('variables', 'workers') || {}
      doc['type'] = 'variables'
      doc['_id'] = 'workers'
      doc['workers'] ||= {}
      doc
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

  def class_name
    self.class.to_s
  end

  def save_info
    @info.save if @info
  end

  def shutdown
    super
    save_info
  end

  def worker_control_variable
    self.class.control_document["workers"][id]
  end

  def desired_state
    control_hash = worker_control_variable ||
      @storage.get("variables", "worker") ||
      { "state" => "running" }
    control_hash["state"]
  end

  def determine_state
    @state_mutex.synchronize do
      if @state != "stopped" && @context["worker_state_enabled"]
        @state = desired_state
        save_info
      end
    end
  end

  def info
    self.class.info[id]
  end
end