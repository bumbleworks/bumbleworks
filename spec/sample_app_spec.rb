require 'spec_helper'
require File.expand_path('../sample_app/config/application', __FILE__)
require File.expand_path('../sample_app/config/specific_directories', __FILE__)

describe "Sample Applications" do
  describe SampleApp do
    describe "Bumbleworks.configure: use default folders" do
      let(:app_root) {File.expand_path('../sample_app', __FILE__)}

      before :each do
        Bumbleworks.reset!
      end

      it 'sets Bumbleworks configuration for application root' do
        described_class.new
        Bumbleworks.root.should == app_root
      end

      it 'discovers default Root/lib/process_definitions folder' do
        described_class.new
        Bumbleworks.definitions_directory.should == File.join(app_root, 'lib/process_definitions')
      end

      it 'discovers default Root/app/participants directory folder' do
        described_class.new
        Bumbleworks.participants_directory.should == File.join(app_root, 'app', 'participants' )
      end

      it 'discovers default Root/participants directory folder' do
        described_class.new
        Bumbleworks.root = File.join(app_root, 'app')
        Bumbleworks.participants_directory.should == File.join(app_root, 'app', 'participants' )
      end
    end
  end

  describe SpecificDirectories do
    describe "Bumbleworks.configure block: use folders defined in block" do
      let(:app_root) {File.expand_path('../sample_app', __FILE__)}

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
end
