class Bumbleworks::WorkerManager
  def initialize(worker_id)
    @worker_id = worker_id
  end

  def info
    Bumbleworks::Worker.info[@worker_id]
  end

  def system_info
    info['system']
  end

  def method_missing(method, *args, &block)
    if info.keys.include?(method.to_s)
      return info[method.to_s]
    end
    super
  end
end