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
        c.autostart_worker = false
      end

      described_class.configure do |c|
        c.autostart_worker = true
      end

      described_class.configuration.root.should == 'pickles'
      described_class.configuration.autostart_worker.should == true
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

  describe '.register_participants' do
    it 'stores the block' do
      participant_block = lambda { bees_honey 'BeesHoney' }
      described_class.register_participants &participant_block
      described_class.instance_variable_get('@participant_block').should == participant_block
    end
  end

  describe '.start!' do
    before :each do
      described_class.reset!
      Bumbleworks::ParticipantRegistration.stub(:autoload_all)
      described_class.stub(:load_process_definitions)
    end

    it 'registers pre-configured participants with ruote' do
      the_block = lambda {}
      described_class.register_participants &the_block
      Bumbleworks::Ruote.should_receive(:register_participants).with(&the_block)
      described_class.start!
    end

    it 'registers process definitions with dashboard' do
      described_class.storage = {}
      described_class.should_receive(:load_process_definitions)
      described_class.start!
    end

    it 'does not automatically start a worker by default' do
      described_class.storage = {}
      described_class.start!
      Bumbleworks::Ruote.dashboard.worker.should be_nil
    end

    it 'starts a worker if autostart_worker config setting is true' do
      described_class.storage = {}
      described_class.autostart_worker = true
      described_class.start!
      Bumbleworks::Ruote.dashboard.worker.should_not be_nil
    end
  end

  describe '.configuration' do
    it 'creates an instance of Bumbleworks::Configuration' do
      described_class.configuration.should be_an_instance_of(Bumbleworks::Configuration)
    end

    it 'returns the same instance when called multiple times' do
      configuration = described_class.configuration
      described_class.configuration.should == configuration
    end
  end
end
