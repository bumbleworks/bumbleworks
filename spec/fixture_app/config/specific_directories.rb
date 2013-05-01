require File.expand_path('../../../../lib/bumbleworks', __FILE__)
class SpecificDirectories
  def initialize
    setup_bumbleworks
  end

  def setup_bumbleworks
    Bumbleworks.configure do |c|
      c.root = File.expand_path('../../', __FILE__)
      c.definitions_directory = 'specific_directory/definitions'
      c.participants_directory = 'specific_directory/participants'
    end
  end
end


