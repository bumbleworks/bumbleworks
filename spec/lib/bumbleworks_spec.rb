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

  describe '.clear_configuration!' do
    it 'resets configuration' do
      old_config = described_class.configuration
      described_class.clear_configuration!
      described_class.configuration.should_not == old_config
    end
  end

  describe '.reset!' do
    it 'resets configuration and resets ruote' do
      expect(Bumbleworks::Ruote).to receive(:reset!).ordered
      expect(described_class).to receive(:clear_configuration!).ordered
      described_class.reset!
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

  describe '.autoload_tasks' do
    it 'autoloads task modules' do
      expect(Bumbleworks::Task).to receive(:autoload_all)
      described_class.autoload_tasks
    end
  end

  describe '.autoload_participants' do
    it 'autoloads participant classes' do
      expect(Bumbleworks::ParticipantRegistration).to receive(:autoload_all)
      described_class.autoload_participants
    end
  end

  describe '.initialize!' do
    it 'autoloads task modules and participant classes' do
      expect(described_class).to receive(:autoload_participants)
      expect(described_class).to receive(:autoload_tasks)
      described_class.initialize!
    end
  end

  describe '.register_participants' do
    it 'autoloads participant classes and registers given participant list' do
      the_block = Proc.new {
        bees_honey 'BeesHoney'
      }
      expect(described_class).to receive(:autoload_participants)
      described_class.register_participants &the_block
      expect(described_class.dashboard.participant_list.map(&:classname)).to eq([
        'Bumbleworks::ErrorDispatcher',
        'Bumbleworks::EntityInteractor',
        'BeesHoney',
        'Bumbleworks::StorageParticipant'
      ])
    end
  end

  describe '.register_default_participants' do
    it 'registers default participants' do
      expect(described_class).not_to receive(:autoload_participants)
      expect(described_class).to receive(:register_participants)
      described_class.register_default_participants
    end
  end

  describe '.load_definitions!' do
    it 'creates all definitions from directory' do
      described_class.stub(:definitions_directory).and_return(:defs_dir)
      expect(Bumbleworks::ProcessDefinition).to receive(:create_all_from_directory!).with(:defs_dir, :fake_options)
      described_class.load_definitions!(:fake_options)
    end

    it 'does nothing if using default path and directory does not exist' do
      described_class.reset!
      described_class.root = File.join(fixtures_path, 'apps', 'minimal')
      expect(Bumbleworks::ProcessDefinition).not_to receive(:create_all_from_directory!)
      described_class.load_definitions!
    end

    it 'raises exception if using custom path and directory does not exist' do
      described_class.reset!
      described_class.root = File.join(fixtures_path, 'apps', 'minimal')
      described_class.definitions_directory = 'oysters'
      expect {
        described_class.load_definitions!
      }.to raise_error(Bumbleworks::InvalidSetting)
    end
  end

  describe '.bootstrap!' do
    it 'loads definitions and participant registration list' do
      expect(described_class).to receive(:load_definitions!)
      expect(Bumbleworks::ParticipantRegistration).to receive(:register!)
      described_class.bootstrap!
    end
  end

  describe '.configuration' do
    before :each do
      Bumbleworks::StorageAdapter.auto_register = nil
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
      Bumbleworks.clear_configuration! # to reload storage adapters
      described_class.configuration.storage_adapters.should include(Bumbleworks::Redis::Adapter)
    end

    it 'automatically adds Sequel adapter if defined' do
      stub_const('Bumbleworks::Sequel::Adapter', Bumbleworks::StorageAdapter)
      Bumbleworks.clear_configuration! # to reload storage adapters
      described_class.configuration.storage_adapters.should include(Bumbleworks::Sequel::Adapter)
    end
  end

  describe 'Bumbleworks::Ruote delegation' do
    it 'includes dashboard' do
      expect(Bumbleworks::Ruote).to receive(:dashboard).and_return(:oh_goodness_me)
      Bumbleworks.dashboard.should == :oh_goodness_me
    end

    it 'includes start_worker' do
      expect(Bumbleworks::Ruote).to receive(:start_worker!).and_return(:lets_do_it)
      Bumbleworks.start_worker!.should == :lets_do_it
    end

    it 'includes cancel_process!' do
      expect(Bumbleworks::Ruote).to receive(:cancel_process!).with(:wfid).and_return(:cancelling)
      Bumbleworks.cancel_process!(:wfid).should == :cancelling
    end

    it 'includes kill_process!' do
      expect(Bumbleworks::Ruote).to receive(:kill_process!).with(:wfid).and_return(:killing)
      Bumbleworks.kill_process!(:wfid).should == :killing
    end

    it 'includes cancel_all_processes!' do
      expect(Bumbleworks::Ruote).to receive(:cancel_all_processes!).and_return(:cancelling)
      Bumbleworks.cancel_all_processes!.should == :cancelling
    end

    it 'includes kill_all_processes!' do
      expect(Bumbleworks::Ruote).to receive(:kill_all_processes!).and_return(:killing)
      Bumbleworks.kill_all_processes!.should == :killing
    end
  end

  describe '.launch!' do
    before :all do
      class LovelyEntity
        attr_accessor :identifier
        def initialize(identifier)
          @identifier = identifier
        end
      end
    end

    after :all do
      Object.send(:remove_const, :LovelyEntity)
    end

    it 'delegates to Bumbleworks::Ruote.launch' do
      expect(Bumbleworks::Ruote).to receive(:launch).with(:amazing_process, :hugs => :love)
      Bumbleworks.launch!(:amazing_process, :hugs => :love)
    end

    it 'sends all args along' do
      expect(Bumbleworks::Ruote).to receive(:launch).with(:amazing_process, { :hugs => :love }, { :whiny => :yup }, :peahen)
      Bumbleworks.launch!(:amazing_process, { :hugs => :love }, { :whiny => :yup }, :peahen)
    end

    it 'expands entity params when entity object provided' do
      expect(Bumbleworks::Ruote).to receive(:launch).with(:amazing_process, { :entity_id => :wiley_e_coyote, :entity_type => 'LovelyEntity' }, :et_cetera)
      Bumbleworks.launch!(:amazing_process, { :entity => LovelyEntity.new(:wiley_e_coyote) }, :et_cetera)
    end

    it 'returns a Bumbleworks::Process instance with the wfid of the launched process' do
      Bumbleworks::Ruote.stub(:launch).with(:amazing_process).and_return('18181818')
      bp = Bumbleworks.launch!(:amazing_process)
      bp.should be_a(Bumbleworks::Process)
      bp.id.should == '18181818'
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

  describe '.store_history' do
    it 'delegates to configuration.logger' do
      described_class.configuration.stub(:store_history).and_return(:why_not)
      described_class.store_history.should == :why_not
    end
  end

  describe '.store_history?' do
    it 'returns true if store_history is true' do
      described_class.store_history = true
      described_class.store_history?.should be_truthy
    end

    it 'returns false if store_history is anything but true' do
      described_class.store_history = false
      described_class.store_history?.should be_falsy
      described_class.store_history = 'penguins'
      described_class.store_history?.should be_falsy
    end
  end
end
