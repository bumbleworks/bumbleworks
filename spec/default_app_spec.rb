require 'spec_helper'
require File.expand_path('../fixture_app/config/default_app', __FILE__)

describe SampleApp do
  describe "Bumbleworks.configure: use default folders" do
    let(:app_root) {File.expand_path('../fixture_app', __FILE__)}

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

