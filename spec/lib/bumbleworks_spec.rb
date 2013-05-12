describe Bumbleworks do
  describe ".configure" do
    it 'yields the current configuration' do
      described_class.configure do |c|
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
    it 'registers a block' do
      participant_block = lambda {}
      Bumbleworks.register_participants &participant_block
      Bumbleworks.participant_block.should == participant_block
    end
  end

  describe '.start!' do
    before :each do
      described_class.reset!
      described_class.stub(:load_participants)
      described_class.stub(:load_process_definitions)
    end

    it 'loads participants registered using #register_participants' do
      described_class.register_participants do
        bees_honey 'BeesHoney'
        maple_syrup 'MapleSyrup'
        catchall 'NewCatchall'
      end

      described_class.storage = {}
      described_class.start!
      described_class.dashboard.participant_list.should have(3).items
      described_class.dashboard.participant_list.map(&:classname).should =~ ['BeesHoney', 'MapleSyrup', 'NewCatchall']
    end

    it 'adds catchall participant if not in list' do
      described_class.register_participants do
        knuckle_sandwich 'KnuckleSandwich'
      end

      described_class.storage = {}
      described_class.start!
      described_class.dashboard.participant_list.should have(2).items
      described_class.dashboard.participant_list.map(&:classname).should =~ ['KnuckleSandwich', 'Ruote::StorageParticipant']
    end

    it 'registers process definitions with dashboard' do
      described_class.should_receive(:register_participant_list)
      described_class.storage = {}
      described_class.should_receive(:registered_process_definitions).and_return({'compile' => 'some definition'})
      described_class.start!
      described_class.dashboard.variables['compile'].should == 'some definition'
    end

    it 'does not automatically start a worker by default' do
      described_class.stub(:register_participant_list)
      described_class.storage = {}
      described_class.start!
      described_class.dashboard.worker.should be_nil
    end

    it 'starts a worker if autostart_worker config setting is true' do
      described_class.stub(:register_participant_list)
      described_class.storage = {}
      described_class.autostart_worker = true
      described_class.start!
      described_class.dashboard.worker.should_not be_nil
    end
  end

  describe '.dashboard' do
    before :each do
      described_class.reset!
    end

    it 'raises an error if no storage is defined' do
      described_class.storage = nil
      expect{described_class.dashboard}.to raise_error Bumbleworks::UndefinedSetting
    end

    it 'creates a new dashboard' do
      described_class.storage = {}
      described_class.dashboard.should be_an_instance_of(Ruote::Dashboard)
    end
  end

  describe '.define_process' do
    it 'delegates to ProcessDefinitions' do
      block = Proc.new {}
      Bumbleworks::ProcessDefinition.should_receive(:define_process).with('name', {}, &block)
      described_class.define_process('name', {}, &block)
    end


    it 'should raise an error when duplicate process names are detected' do
      described_class.define_process('foot-traffic') do
      end

      expect do
        described_class.define_process('foot-traffic') do
        end
      end.to raise_error
    end
  end

  describe '.participant_block' do
    it 'raises error if not in test mode' do
      described_class.env = 'not-in-test-mode'
      expect{described_class.participant_block}.to raise_error Bumbleworks::UnsupportedMode
      described_class.env = 'test'
    end

    it 'returns the registered block' do
      participant_block = lambda {}
      described_class.register_participants &participant_block
      described_class.participant_block.should == participant_block
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

  describe '.ruote_storage' do
    before :each do
      described_class.reset!
    end

    it 'raise error when storage is not defined' do
      expect{described_class.send(:ruote_storage)}.to raise_error Bumbleworks::UndefinedSetting
    end

    it 'handles Hash storage' do
      storage = {}
      described_class.storage = storage
      Ruote::HashStorage.should_receive(:new).with(storage)
      described_class.send(:ruote_storage)
    end

    it 'handles Redis storage' do
      storage = Redis.new
      described_class.storage = storage
      Ruote::Redis::Storage.should_receive(:new).with(storage)
      described_class.send(:ruote_storage)
    end

    it 'handles Sequel storage' do
      storage = Sequel.sqlite
      described_class.storage = storage
      Ruote::Sequel::Storage.should_receive(:new).with(storage)
      described_class.send(:ruote_storage)
    end
  end
end
