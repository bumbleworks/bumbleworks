describe Bumbleworks::Ruote do
  before :each do
    Bumbleworks.reset!
    Bumbleworks.storage = {}
  end

  describe ".cancel_process!" do
    before :each do
      Bumbleworks.start_worker!
    end

    it 'cancels given process' do
      Bumbleworks.define_process 'do_nothing' do
        lazy_guy :task => 'absolutely_nothing'
      end
      process = Bumbleworks.launch!('do_nothing')
      Bumbleworks.dashboard.wait_for(:lazy_guy)
      Bumbleworks.dashboard.process(process.wfid).should_not be_nil
      described_class.cancel_process!(process.wfid)
      Bumbleworks.dashboard.process(process.wfid).should be_nil
    end

    it 'times out if process is not cancelled in time' do
      Bumbleworks.define_process "time_hog" do
        sequence :on_cancel => 'ignore_parents' do
          pigheaded :task => 'whatever'
        end
        define 'ignore_parents' do
          wait '1s'
        end
      end
      process = Bumbleworks.launch!('time_hog')
      Bumbleworks.dashboard.wait_for(:pigheaded)
      Bumbleworks.dashboard.process(process.wfid).should_not be_nil
      expect {
        described_class.cancel_process!(process.wfid, :timeout => 0.5)
      }.to raise_error(Bumbleworks::Ruote::CancelTimeout)
    end
  end

  describe ".kill_process!" do
    before :each do
      Bumbleworks.start_worker!
    end

    it 'kills given process without running on_cancel' do
      Bumbleworks.define_process "do_nothing" do
        sequence :on_cancel => 'rethink_life' do
          lazy_guy :task => 'absolutely_nothing'
        end
        define 'rethink_life' do
          wait '10s'
        end
      end
      process = Bumbleworks.launch!('do_nothing')
      Bumbleworks.dashboard.wait_for(:lazy_guy)
      Bumbleworks.dashboard.process(process.wfid).should_not be_nil
      described_class.kill_process!(process.wfid)
      Bumbleworks.dashboard.process(process.wfid).should be_nil
    end

    it 'times out if process is not killed in time' do
      Bumbleworks.dashboard.stub(:kill)
      Bumbleworks.dashboard.stub(:process).with('woot').and_return(:i_exist)
      expect {
        described_class.kill_process!('woot', :timeout => 0.5)
      }.to raise_error(Bumbleworks::Ruote::KillTimeout)
    end
  end

  describe ".cancel_all_processes!" do
    before :each do
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


    it 'cancels processes which show up while waiting' do
      class Bumbleworks::Ruote
        class << self
          alias_method :original, :send_cancellation_message
          def send_cancellation_message(method, processes)
            # 2. call original method to cancel the processes kicked off below
            original(method, processes)

            # 3. launch some more processes before returning, but only do it once.
            #    These should also be cancelled.
            if !@kicked_off
              Bumbleworks.define_process "do_more_nothing" do
                participant :ref => "lazy_guy_bob", :task => 'absolutely_nothing'
              end

              10.times do
                Bumbleworks.launch!("do_more_nothing")
              end
              @kicked_off = true
            end
          end
        end
      end

      # 1. kick off some processes, wait for them then cancel them.
      5.times do |i|
        Bumbleworks.define_process "do_nothing_#{i}" do
          participant :ref => "lazy_guy_#{i}", :task => 'absolutely_nothing'
        end
        Bumbleworks.launch!("do_nothing_#{i}")
        Bumbleworks.dashboard.wait_for("lazy_guy_#{i}".to_sym)
      end

      Bumbleworks.dashboard.processes.count.should == 5

      described_class.cancel_all_processes!(:timeout => 30)

      # 4. When this is all done, all processes should be cancelled.
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
      described_class.dashboard.should be_an_instance_of(Ruote::Dashboard)
    end

    it 'does not start a worker by default' do
      described_class.dashboard.worker.should be_nil
    end
  end

  describe '.start_worker!' do
    it 'adds new worker to dashboard and returns worker' do
      described_class.dashboard.worker.should be_nil
      new_worker = described_class.start_worker!
      new_worker.should be_an_instance_of(Ruote::Worker)
      described_class.dashboard.worker.should == new_worker
    end

    it 'runs in current thread if :join option is true' do
      ::Ruote::Worker.stub(:new).and_return(worker_double = double('worker'))
      worker_double.should_receive(:run)
      described_class.start_worker!(:join => true)
    end

    it 'runs in new thread and returns worker if :join option not true' do
      ::Ruote::Worker.stub(:new).and_return(worker_double = double('worker'))
      worker_double.should_receive(:run_in_thread)
      described_class.start_worker!.should == worker_double
    end

    it 'sets dashboard to noisy if :verbose option true' do
      described_class.dashboard.should_receive(:noisy=).with(true)
      described_class.start_worker!(:verbose => true)
    end

    it 'registers error handler' do
      described_class.should_receive(:register_error_handler)
      described_class.start_worker!
    end

    it 'calls set_up_storage_history' do
      described_class.should_receive(:set_up_storage_history)
      described_class.start_worker!
    end

    it 'does not add another error_handler_participant if already registered' do
      described_class.register_participants
      described_class.start_worker!
      described_class.dashboard.participant_list.map(&:classname).should == [
        'Bumbleworks::Participant::ErrorHandler', 'Bumbleworks::Participant::StorageParticipant']
      Bumbleworks.dashboard.on_error.flatten[2].should == 'error_handler_participant'
    end
  end

  describe '.set_up_storage_history' do
    it 'adds a storage history service to the dashboard if storage adapter allows it' do
      storage_adapter = double('adapter', :allow_history_storage? => true)
      Bumbleworks.storage_adapter = storage_adapter
      described_class.stub(:storage => Ruote::HashStorage.new({}))
      Bumbleworks.dashboard.should_receive(:add_service).with(
        'history', 'ruote/log/storage_history', 'Ruote::StorageHistory'
      )
      described_class.set_up_storage_history
    end

    it 'does not add a storage history service to the dashboard if not allowed' do
      storage_adapter = double('adapter', :allow_history_storage? => false)
      Bumbleworks.storage_adapter = storage_adapter
      described_class.stub(:storage => Ruote::HashStorage.new({}))
      Bumbleworks.dashboard.should_receive(:add_service).never
      described_class.set_up_storage_history
    end

    it 'does not add a storage history service to the dashboard if turned off in config' do
      storage_adapter = double('adapter', :allow_history_storage? => true)
      Bumbleworks.storage_adapter = storage_adapter
      described_class.stub(:storage => Ruote::HashStorage.new({}))
      Bumbleworks.dashboard.should_receive(:add_service).never
      Bumbleworks.store_history = false
      described_class.set_up_storage_history
    end
  end

  describe '.register_participants' do
    it 'loads participants from given block, adding storage participant catchall' do
      registration_block = Proc.new {
        bees_honey 'BeesHoney'
        maple_syrup 'MapleSyrup'
        catchall 'NewCatchall'
      }

      described_class.dashboard.participant_list.should be_empty
      described_class.register_participants &registration_block
      described_class.dashboard.participant_list.should have(5).items
      described_class.dashboard.participant_list.map(&:classname).should == [
        'Bumbleworks::Participant::ErrorHandler', 'BeesHoney', 'MapleSyrup', 'NewCatchall', 'Bumbleworks::Participant::StorageParticipant']
    end

    it 'does not add storage participant catchall if already exists' do
      registration_block = Proc.new {
        bees_honey 'BeesHoney'
        catchall
      }

      described_class.dashboard.participant_list.should be_empty
      described_class.register_participants &registration_block
      described_class.dashboard.participant_list.should have(3).items
      described_class.dashboard.participant_list.map(&:classname).should == [
        'Bumbleworks::Participant::ErrorHandler', 'BeesHoney', 'Ruote::StorageParticipant'
      ]
    end

    it 'adds catchall and error_handler participants if block is nil' do
      described_class.dashboard.participant_list.should be_empty
      described_class.register_participants &nil
      described_class.dashboard.participant_list.should have(2).item
      described_class.dashboard.participant_list.map(&:classname).should ==
        ['Bumbleworks::Participant::ErrorHandler', 'Bumbleworks::Participant::StorageParticipant']
    end
  end

  describe '.register_error_handler', dev:true do
    it 'registers the error handler participant' do
      described_class.register_error_handler
      Bumbleworks.dashboard.participant_list.map(&:classname).should include('Bumbleworks::Participant::ErrorHandler')
    end

    it 'it sets the global Ruote on_error to the error_handler_participant' do
      described_class.register_error_handler
      Bumbleworks.dashboard.on_error.flatten[2].should == 'error_handler_participant'
    end

    it 'does not override existing error_handler_participant' do
      described_class.register_participants do
        error_handler_participant 'Whatever'
      end
      described_class.register_error_handler
      Bumbleworks.dashboard.participant_list.map(&:classname).should ==
        ['Whatever', 'Bumbleworks::Participant::StorageParticipant']

    end
  end

  describe '.storage' do
    it 'raise error when storage is not defined' do
      Bumbleworks.storage = nil
      expect { described_class.storage }.to raise_error Bumbleworks::UndefinedSetting
    end

    it 'returns new storage from configured adapter' do
      driven_storage = ::Ruote::HashStorage.new({})
      storage = {}
      adapter = double('Adapter')
      options = { :thing => 'yay' }
      adapter.stub(:new_storage).with(storage, options).and_return(driven_storage)
      Bumbleworks.storage = storage
      Bumbleworks.storage_adapter = adapter
      Bumbleworks.storage_options = options
      described_class.storage.should == driven_storage
    end
  end

  describe '.launch' do
    before :each do
      @pdef = Bumbleworks.define_process 'foo' do; end
    end

    it 'tells dashboard to launch process' do
      described_class.dashboard.should_receive(:launch).with(@pdef.tree, 'variable' => 'neat')
      described_class.launch('foo', 'variable' => 'neat')
    end

    it 'sets catchall if needed' do
      described_class.dashboard.participant_list.should be_empty
      described_class.launch('foo')
      described_class.dashboard.participant_list.should have(1).item
      described_class.dashboard.participant_list.first.classname.should == 'Bumbleworks::Participant::StorageParticipant'
    end
  end

  describe '.reset!' do
    it 'purges and shuts down storage, then resets storage' do
      old_storage = described_class.storage
      old_storage.should_receive(:purge!)
      old_storage.should_receive(:shutdown)
      described_class.reset!
      described_class.storage.should_not == old_storage
    end

    it 'skips purging and shutting down of storage if no storage' do
      described_class.instance_variable_set(:@storage, nil)
      expect {
        described_class.reset!
      }.not_to raise_error
    end

    it 'shuts down dashboard and detaches' do
      old_dashboard = described_class.dashboard
      old_dashboard.should_receive(:shutdown)
      described_class.reset!
      described_class.dashboard.should_not == old_dashboard
    end

    it 'skips shutting down dashboard if no dashboard' do
      described_class.instance_variable_set(:@dashboard, nil)
      expect {
        described_class.reset!
      }.not_to raise_error
    end

    it 'skips shutting down dashboard if dashboard can not be shutdown' do
      dashboard = double('dashboard', :respond_to? => false)
      described_class.instance_variable_set(:@dashboard, dashboard)
      dashboard.should_receive(:shutdown).never
      described_class.reset!
      described_class.dashboard.should_not == dashboard
    end
  end
end
