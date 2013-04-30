require 'spec_helper'
require File.expand_path('../fixtures/sample_app1/config/application', __FILE__)

describe SampleApp1 do
  describe "Bumbleworks.configure block" do
    it 'sets Bumbleworks configuration for application root' do
      described_class.new
      Bumbleworks.root.should == File.expand_path('../fixtures/sample_app1', __FILE__)
    end

    it 'discovers default defintions directory relative to root folder' do
      described_class.new
      Bumbleworks.definitions_directory.should == File.join(Bumbleworks.root, 'lib/process_definitions' )
    end

  end
end
