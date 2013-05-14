describe Bumbleworks::Ruote do
  before :each do
    Bumbleworks.reset!
  end

  describe '.dashboard' do
    it 'raises an error if no storage is defined' do
      Bumbleworks.storage = nil
      expect { described_class.dashboard }.to raise_error Bumbleworks::UndefinedSetting
    end

    it 'creates a new dashboard' do
      Bumbleworks.storage = {}
      described_class.dashboard.should be_an_instance_of(Ruote::Dashboard)
    end

    it 'does not start a worker if autostart is false' do
      Bumbleworks.storage = {}
      described_class.dashboard.worker.should be_nil
    end

    it 'starts a worker if autostart is true' do
      Bumbleworks.storage = {}
      Bumbleworks.autostart_worker = true
      described_class.dashboard.worker.should_not be_nil
    end

    it 'starts a worker if :start_worker option is true' do
      Bumbleworks.storage = {}
      described_class.dashboard(:start_worker => true).worker.should_not be_nil
    end
  end

  describe '.start_worker!' do
    it 'adds new worker to dashboard and returns worker' do
      Bumbleworks.storage = {}
      described_class.dashboard.worker.should be_nil
      new_worker = described_class.start_worker!
      new_worker.should be_an_instance_of(Ruote::Worker)
      described_class.dashboard.worker.should == new_worker
    end

    it 'joins current thread if :join option is true' do
      Bumbleworks.storage = {}
      ::Ruote::Dashboard.stub(:new).and_return(dash_double = double('dash', :worker => nil))
      dash_double.should_receive(:join)
      described_class.start_worker!(:join => true)
    end

    it 'returns if :join option not true' do
      Bumbleworks.storage = {}
      ::Ruote::Dashboard.stub(:new).and_return(dash_double = double('dash', :worker => nil))
      dash_double.should_receive(:join).never
      described_class.start_worker!
    end
  end

  describe '.register_participants' do
    it 'loads participants from given block, adding storage participant catchall' do
      registration_block = Proc.new {
        bees_honey 'BeesHoney'
        maple_syrup 'MapleSyrup'
        catchall 'NewCatchall'
      }

      Bumbleworks.storage = {}
      described_class.dashboard.participant_list.should be_empty
      described_class.register_participants &registration_block
      described_class.dashboard.participant_list.should have(4).items
      described_class.dashboard.participant_list.map(&:classname).should =~ ['BeesHoney', 'MapleSyrup', 'NewCatchall', 'Ruote::StorageParticipant']
    end

    it 'does not add storage participant catchall if already exists' do
      registration_block = Proc.new {
        bees_honey 'BeesHoney'
        catchall
      }

      Bumbleworks.storage = {}
      described_class.dashboard.participant_list.should be_empty
      described_class.register_participants &registration_block
      described_class.dashboard.participant_list.should have(2).items
      described_class.dashboard.participant_list.map(&:classname).should =~ ['BeesHoney', 'Ruote::StorageParticipant']
    end

    it 'adds catchall participant if block is nil' do
      Bumbleworks.storage = {}
      described_class.dashboard.participant_list.should be_empty
      described_class.register_participants &nil
      described_class.dashboard.participant_list.should have(1).item
      described_class.dashboard.participant_list.first.classname.should == 'Ruote::StorageParticipant'
    end
  end

  describe '.storage' do
    it 'raise error when storage is not defined' do
      expect { described_class.send(:storage) }.to raise_error Bumbleworks::UndefinedSetting
    end

    it 'handles Hash storage' do
      storage = {}
      Bumbleworks.storage = storage
      Ruote::HashStorage.should_receive(:new).with(storage)
      described_class.send(:storage)
    end

    it 'handles Redis storage' do
      storage = Redis.new
      Bumbleworks.storage = storage
      Ruote::Redis::Storage.should_receive(:new).with(storage)
      described_class.send(:storage)
    end

    it 'handles Sequel storage' do
      storage = Sequel.sqlite
      Bumbleworks.storage = storage
      Ruote::Sequel::Storage.should_receive(:new).with(storage)
      described_class.send(:storage)
    end
  end
end