require File.expand_path('../../../../../lib/bumbleworks', __FILE__)
class SampleApp1
  def initialize
    Bumbleworks.configure do |c|
      c.root = File.expand_path('../../', __FILE__)
    end
  end

  def workflow_engine
    @workflow_engine ||= Bumbleworks.new
  end
end


