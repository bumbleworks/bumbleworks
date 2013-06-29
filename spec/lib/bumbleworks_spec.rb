describe Bumbleworks do
  describe ".configure" do
    it 'yields the current configuration' do
      existing_configuration = described_class.configuration
      described_class.configure do |c|
        expect(c).to equal(existing_configuration)
      end
    end

    it 'allows multiple cumulative configuration blocks' do
      described_class.configure do |c|
        c.root = 'pickles'
      end

      described_class.configure do |c|
        c.storage = 'nerfy'
      end

      described_class.configuration.root.should == 'pickles'
      described_class.configuration.storage.should == 'nerfy'
    end

    it 'requires a block' do
      expect { described_class.configure }.to raise_error(ArgumentError)
    end
  end

  describe ".configure!" do
    it 'resets configuration and yields new configuration' do
      existing_configuration = described_class.configuration
      described_class.configure! do |c|
        expect(c).not_to equal(existing_configuration)
        expect(c).to equal(described_class.configuration)
      end
    end
  end

  describe '.storage' do
    it 'can set directly' do
      storage = double("Storage")
      Bumbleworks.storage = storage
      Bumbleworks.storage.should == storage
      Bumbleworks.configuration.storage.should == storage
    end

    it 'can set with a block' do
      storage = double("Storage")
      Bumbleworks.configure {|c| c.storage = storage }
      Bumbleworks.storage.should == storage
      Bumbleworks.configuration.storage.should == storage
    end
  end

  describe '.register_tasks' do
    it 'autoloads task modules' do
      Bumbleworks::Task.should_receive(:autoload_all)
      described_class.register_tasks
    end
  end

  describe '.register_participants' do
    it 'autoloads and registers participants' do
      the_block = lambda {  }
      Bumbleworks::ParticipantRegistration.should_receive(:autoload_all)
      Bumbleworks::Ruote.should_receive(:register_participants).with(&the_block)
      described_class.register_participants &the_block
    end
  end

  describe '.load_definitions!' do
    it 'creates all definitions from directory' do
      described_class.stub(:definitions_directory).and_return(:defs_dir)
      described_class.storage = {}
      Bumbleworks::ProcessDefinition.should_receive(:create_all_from_directory!).with(:defs_dir, :fake_options)
      described_class.load_definitions!(:fake_options)
    end
  end

  describe '.configuration' do
    before :each do
      Bumbleworks.reset!
    end

    it 'creates an instance of Bumbleworks::Configuration' do
      described_class.configuration.should be_an_instance_of(Bumbleworks::Configuration)
    end

    it 'returns the same instance when called multiple times' do
      configuration = described_class.configuration
      described_class.configuration.should == configuration
    end

    it 'automatically adds Redis adapter if defined' do
      stub_const('Bumbleworks::Redis::Adapter', Bumbleworks::StorageAdapter)
      described_class.configuration.storage_adapters.should include(Bumbleworks::Redis::Adapter)
    end

    it 'automatically adds Sequel adapter if defined' do
      stub_const('Bumbleworks::Sequel::Adapter', Bumbleworks::StorageAdapter)
      described_class.configuration.storage_adapters.should include(Bumbleworks::Sequel::Adapter)
    end
  end

  describe 'Bumbleworks::Ruote delegation' do
    it 'includes dashboard' do
      Bumbleworks::Ruote.should_receive(:dashboard).and_return(:oh_goodness_me)
      Bumbleworks.dashboard.should == :oh_goodness_me
    end

    it 'includes start_worker' do
      Bumbleworks::Ruote.should_receive(:start_worker!).and_return(:lets_do_it)
      Bumbleworks.start_worker!.should == :lets_do_it
    end
  end

  describe '.launch!' do
    class LovelyEntity
      attr_accessor :id
      def initialize(id)
        @id = id
      end
    end

    it 'delegates to Bumbleworks::Ruote.launch' do
      Bumbleworks::Ruote.should_receive(:launch).with(:amazing_process, :hugs => :love)
      Bumbleworks.launch!(:amazing_process, :hugs => :love)
    end

    it 'expands entity params when entity object provided' do
      Bumbleworks::Ruote.should_receive(:launch).with(:amazing_process, :entity_id => :wiley_e_coyote, :entity_type => 'LovelyEntity')
      Bumbleworks.launch!(:amazing_process, :entity => LovelyEntity.new(:wiley_e_coyote))
    end

    it 'uses "identifier" method instead of id, if entity has one' do
      entity = LovelyEntity.new(5)
      entity.stub(:identifier).and_return(:five)
      Bumbleworks::Ruote.should_receive(:launch).with(:amazing_process, :entity_id => :five, :entity_type => 'LovelyEntity')
      Bumbleworks.launch!(:amazing_process, :entity => entity)
    end

    it 'throws exception if entity has nil id' do
      expect {
        Bumbleworks.launch!(:amazing_process, :entity => LovelyEntity.new(nil))
      }.to raise_error(Bumbleworks::InvalidEntity)
    end

    it 'throws exception if entity is invalid object' do
      expect {
        Bumbleworks.launch!(:amazing_process, :entity => :give_me_a_break)
      }.to raise_error(Bumbleworks::InvalidEntity)
    end
  end

  describe '.logger' do
    it 'delegates to configuration.logger' do
      described_class.configuration.stub(:logger).and_return(:a_logger)
      described_class.logger.should == :a_logger
    end
  end
end
