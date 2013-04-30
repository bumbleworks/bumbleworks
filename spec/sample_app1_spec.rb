require 'spec_helper'
require File.expand_path('../fixtures/sample_app1/config/application', __FILE__)

describe SampleApp1 do
  describe "Bumbleworks.configure block" do
    let(:app_root) {File.expand_path('../fixtures/sample_app1', __FILE__)}

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
      described_class.any_instance.stub(:setup_bumbleworks) do
        Bumbleworks.configure do |c|
          c.root = File.join(app_root, 'app')
        end
      end
      described_class.new
      Bumbleworks.participants_directory.should == File.join(app_root, 'app', 'participants' )
    end
  end
end
