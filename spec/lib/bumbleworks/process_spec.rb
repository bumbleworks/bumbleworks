require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))

describe Bumbleworks::Process do
  before :each do
    Bumbleworks.reset!
    Bumbleworks.storage = {}
    Bumbleworks::Ruote.register_participants
    Bumbleworks.start_worker!

    Bumbleworks.define_process 'going_to_the_dance' do
      concurrence do
        wait_for_event :an_invitation
        await :left_tag => 'a_friend'
      end
    end
    Bumbleworks.define_process 'straightening_the_rocks' do
      concurrence do
        wait_for_event :rock_caliper_delivery
        wait_for_event :speedos
      end
    end
  end

  describe '.new' do
    it 'sets workflow id' do
      bp = described_class.new('apples')
      bp.id.should == 'apples'
    end
  end

  describe '#wfid' do
    it 'is aliased to id' do
      bp = described_class.new('smorgatoof')
      bp.wfid.should == 'smorgatoof'
    end
  end

  describe '#tasks' do
    it 'returns task query filtered for this process' do
      bp = described_class.new('chumpy')
      Bumbleworks::Task.stub(:for_process).with('chumpy').and_return(:my_task_query)
      bp.tasks.should == :my_task_query
    end
  end

  describe '#trackers' do
    it 'lists all trackers this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.trackers.count == 2 && bp2.trackers.count == 2 }
      bp1.trackers.map { |t| t['msg']['fei']['wfid'] }.should == [bp1.wfid, bp1.wfid]
      bp2.trackers.map { |t| t['msg']['fei']['wfid'] }.should == [bp2.wfid, bp2.wfid]
      bp1.trackers.map { |t| t['action'] }.should == ['left_tag', 'left_tag']
      bp2.trackers.map { |t| t['action'] }.should == ['left_tag', 'left_tag']
      bp1.trackers.map { |t| t['conditions']['tag'] }.should == [['an_invitation'], ['a_friend']]
      bp2.trackers.map { |t| t['conditions']['tag'] }.should == [['rock_caliper_delivery'], ['speedos']]
    end
  end

  describe '#all_subscribed_tags' do
    it 'lists all tags this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.trackers.count == 2 && bp2.trackers.count == 2 }
      bp1.all_subscribed_tags.should == { :global => ['an_invitation'], bp1.wfid => ['a_friend'] }
      bp2.all_subscribed_tags.should == { :global => ['rock_caliper_delivery', 'speedos'] }
    end
  end

  describe '#subscribed_events' do
    it 'lists all events (global tags) this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.trackers.count == 2 && bp2.trackers.count == 2 }
      bp1.subscribed_events.should == ['an_invitation']
      bp2.subscribed_events.should == ['rock_caliper_delivery', 'speedos']
    end
  end

  describe '#is_waiting_for?' do
    it 'returns true if event is in subscribed events' do
      bp = described_class.new('whatever')
      bp.stub(:subscribed_events => ['ghosts', 'mouses'])
      bp.is_waiting_for?('mouses').should be_true
    end

    it 'converts symbolized queries' do
      bp = described_class.new('whatever')
      bp.stub(:subscribed_events => ['ghosts', 'mouses'])
      bp.is_waiting_for?(:ghosts).should be_true
    end

    it 'returns false if event is not in subscribed events' do
      bp = described_class.new('whatever')
      bp.stub(:subscribed_events => ['ghosts', 'mouses'])
      bp.is_waiting_for?('organs').should be_false
    end
  end

  describe '#kill!' do
    it 'kills process' do
      bp = described_class.new('frogheads')
      Bumbleworks.should_receive(:kill_process!).with('frogheads')
      bp.kill!
    end
  end

  describe '#cancel!' do
    it 'cancels process' do
      bp = described_class.new('frogheads')
      Bumbleworks.should_receive(:cancel_process!).with('frogheads')
      bp.cancel!
    end
  end

  describe '#==' do
    it 'returns true if other object has same wfid' do
      bp1 = described_class.new('in_da_sky')
      bp2 = described_class.new('in_da_sky')
      bp1.should == bp2
    end
  end

  describe '#entity' do
    it 'returns nil if process not ready yet' do
      bp = described_class.new('nothing')
      bp.entity.should be_nil
    end

    it 'returns entity provided at launch' do
      rainbow_loom = RainbowLoom.new('1234')
      bp = Bumbleworks.launch!('going_to_the_dance', :entity => rainbow_loom)
      wait_until { bp.trackers.count > 0 }
      bp.entity.should == rainbow_loom
    end

    it 'raises exception if multiple workitems have conflicting entity info' do
      Bumbleworks.define_process 'conflict_this' do
        concurrence do
          sequence do
            set 'entity_id' => 'swoo'
            just_wait
          end
          sequence do
            set 'entity_id' => 'fwee'
            just_wait
          end
        end
      end
      bp = Bumbleworks.launch!('conflict_this', :entity => RainbowLoom.new('1234'))
      Bumbleworks.dashboard.wait_for(:just_wait)
      expect {
        bp.entity
      }.to raise_error(Bumbleworks::Process::EntityConflict)
    end

    it 'returns nil if no entity' do
      bp = Bumbleworks.launch!('going_to_the_dance')
      wait_until { bp.trackers.count > 0 }
      bp.entity.should be_nil
    end
  end

  describe '#process_status' do
    it 'returns a process_status instance for the wfid' do
      bp = described_class.new('frogheads')
      Bumbleworks.dashboard.stub(:process).with('frogheads').and_return(:the_status)
      bp.process_status.should == :the_status
    end
  end

  describe '#method_missing' do
    it 'calls method on object returned by #process_status' do
      ps = double('process_status')
      ps.stub(:nuffle).with(:yay).and_return(:its_a_me)
      bp = described_class.new('frogheads')
      bp.stub(:process_status => ps)
      bp.nuffle(:yay).should == :its_a_me
    end

    it 'falls back to method missing if no process status method' do
      bp = described_class.new('blah')
      bp.stub(:process_status => double('process status'))
      expect {
        bp.kerplunk!(:oh_no)
      }.to raise_error
    end
  end
end