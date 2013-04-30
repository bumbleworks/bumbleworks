require 'spec_helper'

describe Bumbleworks::Configuration do
  let(:configuration) {described_class.new}
  before :each do
    configuration.clear!
  end

  describe "#root" do
    it 'raises an error if client did not define' do
      expect{configuration.root}.to raise_error Bumbleworks::Configuration::UndefinedSetting
    end

    it 'returns folder set by user' do
      configuration.root = '/what/about/that'
      configuration.root.should == '/what/about/that'
    end
  end

  describe "#definitions_directory" do
    it 'returns the folder which was set by the client app' do
      configuration.definitions_directory = '/dog/ate/my/homework'
      configuration.definitions_directory.should == '/dog/ate/my/homework'
    end

    it 'returns the default folder if not set by client app' do
      configuration.root = '/Root'
      configuration.definitions_directory.should == '/Root/lib/process_definitions'
    end
  end

  describe '#clear!' do
    it 'resets #root' do
      configuration.root = '/Root'
      configuration.clear!
      expect{configuration.root}.to raise_error Bumbleworks::Configuration::UndefinedSetting
    end

    it 'resets #definitions_directory' do
      configuration.definitions_directory = 'One/Two'
      configuration.definitions_directory.should == 'One/Two'
      configuration.clear!
      configuration.root = '/Root'
      configuration.definitions_directory.should == '/Root/lib/process_definitions'
    end
  end
end
