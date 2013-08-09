class Tracer
  def initialize
    @trace = []
  end

  def << s
    s.strip! if s.is_a?(String)
    @trace << s
  end

  def == other
    @trace == other
  end
end
