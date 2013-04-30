require '../../lib/bumbleworks.rb'
class SomeFramework
  def initialize
    Bumbleworks.configure do |c|
      c.root = File.directory(__FILE__)
    end
  end

  def workflow_engine
    @workflow_engine ||= Bumbleworks.new
  end
end


