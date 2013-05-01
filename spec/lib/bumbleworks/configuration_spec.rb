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

    it 'uses Rails.root if Rails is defined' do
      class Rails
        def self.root
          '/Rails/Root'
        end
      end

      configuration.root.should == '/Rails/Root'
      Object.send(:remove_const, :Rails)
    end

    it 'uses Sinatra::Application.root if defined' do
      class Sinatra
        class Application
          def self.root
            '/Sinatra/Root'
          end
        end
      end

      configuration.root.should == '/Sinatra/Root'
      Object.send(:remove_const, :Sinatra)
    end

    it 'uses Rory.root if defined' do
      class Rory
        def self.root
          '/Rory/Root'
        end
      end

      configuration.root.should == '/Rory/Root'
      Object.send(:remove_const, :Rory)
    end
  end

  describe "#definitions_directory" do
    it 'returns the folder which was set by the client app' do
      File.stub(:directory?).with('/dog/ate/my/homework').and_return(true)
      configuration.definitions_directory = '/dog/ate/my/homework'
      configuration.definitions_directory.should == '/dog/ate/my/homework'
    end

    it 'returns the default folder if not set by client app' do
      File.stub(:directory? => true)
      configuration.root = '/Root'
      configuration.definitions_directory.should == '/Root/lib/process_definitions'
    end

    it 'raises an error if default folder not found' do
      configuration.root = '/Root'
      expect{configuration.definitions_directory}.to raise_error Bumbleworks::Configuration::InvalidSetting
    end

    it 'raises an error if specific folder not found' do
      configuration.definitions_directory = '/mumbo/jumbo'
      expect{configuration.definitions_directory}.to raise_error Bumbleworks::Configuration::InvalidSetting
    end
  end

  describe "#participants_directory" do
    it 'returns the folder which was set by the client app' do
      File.stub(:directory?).with('/dog/ate/my/homework').and_return(true)
      configuration.participants_directory = '/dog/ate/my/homework'
      configuration.participants_directory.should == '/dog/ate/my/homework'
    end

    it 'returns the default folder if not set by client app' do
      File.stub(:directory? => false)
      File.stub(:directory?).with('/Root/app/participants').and_return(true)
      configuration.root = '/Root'
      configuration.participants_directory.should == '/Root/app/participants'
    end

    it 'raises an error if default folder not found' do
      configuration.root = '/Root'
      expect{configuration.participants_directory}.to raise_error Bumbleworks::Configuration::InvalidSetting
    end

    it 'raises an error if specific folder not found' do
      configuration.participants_directory = '/mumbo/jumbo'
      expect{configuration.participants_directory}.to raise_error Bumbleworks::Configuration::InvalidSetting
    end
  end

  describe "#storage" do
    it 'can set storage directly' do
      storage = double("Storage")
      configuration.storage = storage
      configuration.storage.should == storage
    end
  end

  describe '#clear!' do
    it 'resets #root' do
      configuration.root = '/Root'
      configuration.clear!
      expect{configuration.root}.to raise_error Bumbleworks::Configuration::UndefinedSetting
    end

    it 'resets #definitions_directory' do
      File.stub(:directory? => true)
      configuration.definitions_directory = '/One/Two'
      configuration.definitions_directory.should == '/One/Two'
      configuration.clear!

      configuration.root = '/Root'
      configuration.definitions_directory.should == '/Root/lib/process_definitions'
    end
  end
end
