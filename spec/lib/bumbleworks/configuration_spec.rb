describe Bumbleworks::Configuration do
  let(:configuration) {described_class.new}
  before :each do
    configuration.clear!
  end

  describe "#root" do
    it 'raises an error if client did not define' do
      expect{configuration.root}.to raise_error Bumbleworks::UndefinedSetting
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

      configuration.root.should == '/Rails/Root/lib/bumbleworks'
      Object.send(:remove_const, :Rails)
    end

    it 'uses Padrino.root if defined' do
      class Padrino
        def self.root
          '/Padrino/Root'
        end
      end

      configuration.root.should == '/Padrino/Root/lib/bumbleworks'
      Object.send(:remove_const, :Padrino)
    end

    it 'uses Sinatra::Application.root if defined' do
      class Sinatra
        class Application
          def self.root
            '/Sinatra/Root'
          end
        end
      end

      configuration.root.should == '/Sinatra/Root/lib/bumbleworks'
      Object.send(:remove_const, :Sinatra)
    end

    it 'uses Rory.root if defined' do
      class Rory
        def self.root
          '/Rory/Root'
        end
      end

      configuration.root.should == '/Rory/Root/lib/bumbleworks'
      Object.send(:remove_const, :Rory)
    end

    it 'raises error if automatic root detection returns nil' do
      class Rails
        def self.root
          nil
        end
      end

      expect{configuration.root}.to raise_error Bumbleworks::UndefinedSetting
      Object.send(:remove_const, :Rails)
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
      configuration.definitions_directory.should == '/Root/process_definitions'
    end

    it 'returns the second default folder if first does not exist' do
      File.stub(:directory?).with('/Root/process_definitions').and_return(false)
      File.stub(:directory?).with('/Root/processes').and_return(true)
      configuration.root = '/Root'
      configuration.definitions_directory.should == '/Root/processes'
    end

    it 'returns nil if default folder not found' do
      configuration.root = '/Root'
      configuration.definitions_directory.should be_nil
    end

    it 'raises error if specific folder not found' do
      configuration.definitions_directory = '/mumbo/jumbo'
      expect {
        configuration.definitions_directory
      }.to raise_error(
        Bumbleworks::InvalidSetting,
        "Definitions directory not found (looked for /mumbo/jumbo)"
      )
    end
  end

  describe "#participants_directory" do
    it 'returns the folder which was set by the client app' do
      File.stub(:directory?).with('/dog/ate/my/homework').and_return(true)
      configuration.participants_directory = '/dog/ate/my/homework'
      configuration.participants_directory.should == '/dog/ate/my/homework'
    end

    it 'returns the default folder if not set by client app' do
      File.stub(:directory?).with('/Root/participants').and_return(true)
      configuration.root = '/Root'
      configuration.participants_directory.should == '/Root/participants'
    end

    it 'returns nil if default folder not found' do
      configuration.root = '/Root'
      configuration.participants_directory.should be_nil
    end

    it 'raises error if specific folder not found' do
      configuration.participants_directory = '/mumbo/jumbo'
      expect {
        configuration.participants_directory
      }.to raise_error(
        Bumbleworks::InvalidSetting,
        "Participants directory not found (looked for /mumbo/jumbo)"
      )
    end
  end

  describe "#tasks_directory" do
    it 'returns the folder which was set by the client app' do
      File.stub(:directory?).with('/dog/ate/my/homework').and_return(true)
      configuration.tasks_directory = '/dog/ate/my/homework'
      configuration.tasks_directory.should == '/dog/ate/my/homework'
    end

    it 'returns the default folder if not set by client app' do
      File.stub(:directory?).with('/Root/tasks').and_return(true)
      configuration.root = '/Root'
      configuration.tasks_directory.should == '/Root/tasks'
    end

    it 'returns nil if default folder not found' do
      configuration.root = '/Root'
      configuration.tasks_directory.should be_nil
    end

    it 'raises error if specific folder not found' do
      configuration.tasks_directory = '/mumbo/jumbo'
      expect {
        configuration.tasks_directory
      }.to raise_error(
        Bumbleworks::InvalidSetting,
        "Tasks directory not found (looked for /mumbo/jumbo)"
      )
    end
  end

  describe "#participant_registration_file" do
    it 'returns the path which was set by the client app' do
      File.stub(:file?).with('/can/i/get/a/rooster.rb').and_return(true)
      configuration.participant_registration_file = '/can/i/get/a/rooster.rb'
      configuration.participant_registration_file.should == '/can/i/get/a/rooster.rb'
    end

    it 'returns the default folder if not set by client app' do
      File.stub(:file?).with('/Root/participants.rb').and_return(true)
      configuration.root = '/Root'
      configuration.participant_registration_file.should == '/Root/participants.rb'
    end

    it 'returns nil if default path not found' do
      configuration.root = '/Root'
      configuration.participant_registration_file.should be_nil
    end

    it 'raises error if specific path not found' do
      configuration.participant_registration_file = '/do/not/eat/friendly/people.rb'
      expect {
        configuration.participant_registration_file
      }.to raise_error(
        Bumbleworks::InvalidSetting,
        "Participant registration file not found (looked for /do/not/eat/friendly/people.rb)"
      )
    end
  end

  describe '#logger' do
    it 'returns the registered logger' do
      configuration.logger = :a_logger
      configuration.logger.should == :a_logger
    end

    it 'returns the default simple logger if no logger registered' do
      configuration.logger.should == Bumbleworks::SimpleLogger
    end
  end

  describe '#observers' do
    it 'is empty by default' do
      configuration.observers.should be_empty
    end

    it 'returns the registered observers' do
      configuration.observers = [:smash, :pumpkin]
      configuration.observers << :rhubarb
      configuration.observers.should == [:smash, :pumpkin, :rhubarb]
    end
  end

  describe '#entity_classes' do
    it 'is empty by default' do
      configuration.entity_classes.should be_empty
    end

    it 'returns the registered entity classes' do
      configuration.entity_classes = [:fumpin, :nuffin]
      configuration.entity_classes << :summin
      configuration.entity_classes.should == [:fumpin, :nuffin, :summin]
    end
  end

  describe "#storage" do
    it 'can set storage directly' do
      storage = double("Storage")
      configuration.storage = storage
      configuration.storage.should == storage
    end
  end

  describe '#storage_options' do
    it 'defaults to empty hash' do
      subject.storage_options.should == {}
    end

    it 'can be overridden' do
      subject.storage_options = { :smooshie => 'wubbles' }
      subject.storage_options.should == { :smooshie => 'wubbles' }
    end
  end

  describe "#storage_adapter" do
    it 'defaults to first adapter in registered list that uses storage' do
      right_adapter = double('right', :use? => true)
      wrong_adapter_1 = double('wrong1', :use? => false)
      wrong_adapter_2 = double('wrong2', :use? => false)
      subject.stub(:storage_adapters => [wrong_adapter_1, right_adapter, wrong_adapter_2])
      subject.storage_adapter.should == right_adapter
    end

    it 'can be set storage directly' do
      storage = double("Storage Adapter")
      subject.storage_adapter = storage
      subject.storage_adapter.should == storage
    end

    it 'raises UndefinedSetting if no matching storage adapter' do
      wrong_adapter = double('wrong1', :use? => false, :display_name => 'Wrong')
      subject.stub(:storage_adapters => [wrong_adapter])
      expect {
        subject.storage_adapter
      }.to raise_error(Bumbleworks::UndefinedSetting,
        "Storage is missing or not supported.  Supported: Wrong")
    end

    it 'raises UndefinedSetting if no storage adapters' do
      expect {
        subject.storage_adapter
      }.to raise_error(Bumbleworks::UndefinedSetting,
        "No storage adapters configured")
    end
  end

  describe '#add_storage_adapter' do
    it 'adds storage adapter to registered list' do
      GoodForNothingStorage = double('fake_storage', :respond_to? => true)
      configuration.storage_adapters.should be_empty
      configuration.add_storage_adapter(GoodForNothingStorage)
      configuration.add_storage_adapter(Bumbleworks::HashStorage)
      configuration.storage_adapters.should =~ [
        GoodForNothingStorage, Bumbleworks::HashStorage
      ]
    end

    it 'raises ArgumentError if object is not a storage adapter' do
      expect {
        configuration.add_storage_adapter(:nice_try_buddy)
      }.to raise_error(ArgumentError)
    end
  end

  describe '#clear!' do
    it 'resets #root' do
      configuration.root = '/Root'
      configuration.clear!
      expect{configuration.root}.to raise_error Bumbleworks::UndefinedSetting
    end

    it 'resets #definitions_directory' do
      File.stub(:directory? => true)
      configuration.definitions_directory = '/One/Two'
      configuration.definitions_directory.should == '/One/Two'
      configuration.clear!

      configuration.root = '/Root'
      configuration.definitions_directory.should == '/Root/process_definitions'
    end
  end

  describe '#error_handlers', dev:true do
    let(:super_handler) {double('error_handler')}
    it 'sets default error handler' do
      configuration.error_handlers.should == [Bumbleworks::ErrorLogger]
    end

    it 'replaces default handler' do
      configuration.error_handlers = [super_handler]
      configuration.error_handlers.should == [super_handler]
    end

    it 'adds to default handler' do
      configuration.error_handlers << super_handler
      configuration.error_handlers.should =~ [Bumbleworks::ErrorLogger, super_handler]
    end
  end

  describe '#store_history' do
    it 'defaults to true' do
      subject.store_history.should be_true
    end

    it 'can be overridden' do
      subject.store_history = false
      subject.store_history.should be_false
    end
  end
end
