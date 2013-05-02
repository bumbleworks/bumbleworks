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
      Bumbleworks.stub(:load_participants)
      Bumbleworks.stub(:load_process_definitions)
    end

    it 'loads and registers the participants' do
      participant_block = Proc.new do
      end

      Bumbleworks.storage = {}
      Bumbleworks.register_participants &participant_block
      Bumbleworks.engine.should_receive(:register).with(&participant_block)
      Bumbleworks.start!
    end

    it 'calls participant block to register them' do
      participant_block = Proc.new do
        catchall
      end

      Bumbleworks.storage = {}
      Bumbleworks.register_participants &participant_block
      Bumbleworks.engine.should_receive(:register).and_call_original
      Bumbleworks.start!
      Bumbleworks.engine.participant_list.first.should be_an_instance_of(Ruote::ParticipantEntry)
    end


    it 'calls catchall participant if no participants are defined' do

    end

    it 'raises error if no process definitions are loaded' do
    end

  end

  describe '.engine' do
    before :each do
      Bumbleworks.reset!
    end

    it 'raises an error if no storage is defined' do
      Bumbleworks.storage = nil
      expect{Bumbleworks.engine}.to raise_error Bumbleworks::UndefinedSetting
    end

    it 'creates a new engine' do
      Bumbleworks.storage = {}
      Bumbleworks.engine.should be_an_instance_of(Ruote::Dashboard)
    end
  end

  describe '.participant_block' do
    it 'raises error if not in test mode' do
      Bumbleworks.env = 'not-in-test-mode'
      expect{Bumbleworks.participant_block}.to raise_error Bumbleworks::UnsupportedMode
      Bumbleworks.env = 'test'
    end

    it 'returns the registered block' do
      participant_block = lambda {}
      Bumbleworks.register_participants &participant_block
      Bumbleworks.participant_block.should == participant_block
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
