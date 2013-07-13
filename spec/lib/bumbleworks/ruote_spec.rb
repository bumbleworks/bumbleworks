describe Bumbleworks::Ruote do
  before :each do
    Bumbleworks.reset!
  end

  describe ".cancel_all_processes!" do
    before :each do
      Bumbleworks.storage = {}
      Bumbleworks::Ruote.register_participants
      Bumbleworks.start_worker!
    end

    it 'cancels all processes' do
      5.times do |i|
        Bumbleworks.define_process "do_nothing_#{i}" do
          participant :ref => "lazy_guy_#{i}", :task => 'absolutely_nothing'
        end
        Bumbleworks.launch!("do_nothing_#{i}")
        Bumbleworks.dashboard.wait_for("lazy_guy_#{i}".to_sym)
      end
      Bumbleworks.dashboard.processes.count.should == 5
      described_class.cancel_all_processes!
      Bumbleworks.dashboard.processes.count.should == 0
    end

    it 'times out if processes are not cancelled in time' do
      Bumbleworks.define_process "time_hog" do
        sequence :on_cancel => 'ignore_parents' do
          pigheaded :task => 'whatever'
        end
        define 'ignore_parents' do
          wait '1s'
        end
      end
      Bumbleworks.launch!('time_hog')
      Bumbleworks.dashboard.wait_for(:pigheaded)
      Bumbleworks.dashboard.processes.count.should == 1
      expect {
        described_class.cancel_all_processes!(:timeout => 0.5)
      }.to raise_error(Bumbleworks::Ruote::CancelTimeout)
    end
  end

  describe ".kill_all_processes!" do
    before :each do
      Bumbleworks.storage = {}
      Bumbleworks::Ruote.register_participants
      Bumbleworks.start_worker!
    end

    it 'kills all processes without running on_cancel' do
      5.times do |i|
        Bumbleworks.define_process "do_nothing_#{i}" do
          sequence :on_cancel => 'rethink_life' do
            participant :ref => "lazy_guy_#{i}", :task => 'absolutely_nothing'
          end
          define 'rethink_life' do
            wait '10s'
          end
        end
        Bumbleworks.launch!("do_nothing_#{i}")
        Bumbleworks.dashboard.wait_for("lazy_guy_#{i}".to_sym)
      end
      Bumbleworks.dashboard.processes.count.should == 5
      described_class.kill_all_processes!
      Bumbleworks.dashboard.processes.count.should == 0
    end

    it 'times out if processes are not killed in time' do
      Bumbleworks.dashboard.stub(:kill)
      ps1 = double('process', :wfid => nil)
      Bumbleworks.dashboard.stub(:processes).and_return([ps1])
      expect {
        described_class.kill_all_processes!(:timeout => 0.5)
      }.to raise_error(Bumbleworks::Ruote::KillTimeout)
    end
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

    it 'does not start a worker by default' do
      Bumbleworks.storage = {}
      described_class.dashboard.worker.should be_nil
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
      dash_double.should_receive(:noisy=).with(false)
      dash_double.should_receive(:join)
      described_class.start_worker!(:join => true)
    end

    it 'returns if :join option not true' do
      Bumbleworks.storage = {}
      ::Ruote::Dashboard.stub(:new).and_return(dash_double = double('dash', :worker => nil))
      dash_double.should_receive(:noisy=).with(false)
      dash_double.should_receive(:join).never
      described_class.start_worker!
    end

    it 'sets dashboard to noisy if :verbose option true' do
      Bumbleworks.storage = {}
      ::Ruote::Dashboard.stub(:new).and_return(dash_double = double('dash', :worker => nil))
      dash_double.should_receive(:noisy=).with(true)
      described_class.start_worker!(:verbose => true)
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
      described_class.dashboard.participant_list.map(&:classname).should =~ ['BeesHoney', 'MapleSyrup', 'NewCatchall', 'Bumbleworks::StorageParticipant']
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
      described_class.dashboard.participant_list.first.classname.should == 'Bumbleworks::StorageParticipant'
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
  end
end