require File.expand_path('../../../../../lib/bumbleworks', __FILE__)
class SampleApp1
  def initialize
    setup_bumbleworks
  end

  def setup_bumbleworks
    Bumbleworks.root = File.expand_path('../../', __FILE__)
  end
end


