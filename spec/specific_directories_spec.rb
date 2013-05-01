require File.expand_path('../fixture_app/config/specific_directories', __FILE__)

describe SpecificDirectories do
  describe "Bumbleworks.configure block: use folders defined in block" do
    let(:app_root) {File.expand_path('../fixture_app', __FILE__)}

    it ' default Root/specific_directory/definitions folder' do
      described_class.new
      Bumbleworks.definitions_directory.should == File.join(app_root, 'specific_directory/definitions')
    end

    it 'discovers default Root/specific_directory/participants directory folder' do
      described_class.new
      Bumbleworks.participants_directory.should == File.join(app_root, 'specific_directory', 'participants' )
    end
  end
end
