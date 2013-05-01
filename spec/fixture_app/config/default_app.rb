require File.expand_path('../../../../lib/bumbleworks', __FILE__)
class SampleApp
  def initialize
    setup_bumbleworks
    register_participants
  end

  def setup_bumbleworks
    Bumbleworks.configure do |c|
      c.root = File.expand_path('../../', __FILE__)
    end
  end

  def register_participants
    Bumbleworks.register_participants do
      update_status StatusChangeParticipant
    end
  end
end


