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
        await :participant => 'some_darling_cat'
      end
    end
    Bumbleworks.define_process 'straightening_the_rocks' do
      concurrence do
        wait_for_event :rock_caliper_delivery
        wait_for_event :speedos
      end
    end
    Bumbleworks.define_process 'i_wait_for_nobody' do
      tough_guy :task => 'blow_this_thing_wide_open'
    end
  end

  context 'aggregate methods' do
    before(:each) do
      @bp1 = Bumbleworks.launch!('going_to_the_dance')
      @bp2 = Bumbleworks.launch!('going_to_the_dance')
      @bp3 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { Bumbleworks.dashboard.process_wfids.count == 3 }
    end

    describe '.all' do
      it 'returns instances for all process wfids' do
        described_class.all.should =~ [@bp1, @bp2, @bp3]
      end
    end

    describe '.ids' do
      it 'returns all process wfids' do
        described_class.ids.should =~ [@bp1.wfid, @bp2.wfid, @bp3.wfid]
      end
    end

    describe '.count' do
      it 'returns number of processes' do
        described_class.count.should == 3
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

  describe '#workitems' do
    it 'returns task query filtered for this process' do
      bp = described_class.new('chumpy')
      l1 = double(:applied_workitem => 'aw1')
      l2 = double(:applied_workitem => 'aw2')
      l3 = double(:applied_workitem => 'aw3')
      bp.stub(:leaves => [l1, l2, l3])
      bp.workitems.should == [
        Bumbleworks::Workitem.new('aw1'),
        Bumbleworks::Workitem.new('aw2'),
        Bumbleworks::Workitem.new('aw3')
      ]
    end
  end

  describe '#entity_fields' do
    it 'returns empty hash if process not ready yet' do
      bp = described_class.new('nothing')
      bp.entity_fields.should == {}
    end

    it 'returns empty hash if no entity' do
      bp = Bumbleworks.launch!('going_to_the_dance')
      wait_until { bp.reload.trackers.count > 0 }
      bp.entity_fields.should == {}
    end

    it 'returns entity_fields provided at launch' do
      rainbow_loom = RainbowLoom.new('1234')
      bp = Bumbleworks.launch!('going_to_the_dance', :entity => rainbow_loom)
      wait_until { bp.reload.trackers.count > 0 }
      bp.entity_fields.should == { :type => 'RainbowLoom', :identifier => '1234'}
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
        bp.entity_fields
      }.to raise_error(Bumbleworks::Process::EntityConflict)
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
      wait_until { bp1.reload.trackers.count == 3 && bp2.reload.trackers.count == 2 }
      bp1.trackers.map { |t| t.process }.should == [bp1, bp1, bp1]
      bp2.trackers.map { |t| t.process }.should == [bp2, bp2]
      bp1.trackers.map { |t| t.action }.should == ['left_tag', 'left_tag', 'dispatch']
      bp2.trackers.map { |t| t.action }.should == ['left_tag', 'left_tag']
      bp1.trackers.map { |t| t.conditions['tag'] }.should == [['an_invitation'], ['a_friend'], nil]
      bp2.trackers.map { |t| t.conditions['tag'] }.should == [['rock_caliper_delivery'], ['speedos']]
    end
  end

  describe '#all_subscribed_tags' do
    it 'lists all tags this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.reload.trackers.count == 3 && bp2.reload.trackers.count == 2 }
      bp1.all_subscribed_tags.should == { :global => ['an_invitation'], bp1.wfid => ['a_friend'] }
      bp2.all_subscribed_tags.should == { :global => ['rock_caliper_delivery', 'speedos'] }
    end

    it 'sets global tags to empty array by default' do
      bp = Bumbleworks.launch!('i_wait_for_nobody')
      wait_until { bp.reload.tasks.count == 1 }
      bp.all_subscribed_tags.should == { :global => [] }
    end
  end

  describe '#subscribed_events' do
    it 'lists all events (global tags) this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.reload.trackers.count == 3 && bp2.reload.trackers.count == 2 }
      bp1.subscribed_events.should == ['an_invitation']
      bp2.subscribed_events.should == ['rock_caliper_delivery', 'speedos']
    end

    it 'returns empty array if no global tags' do
      bp = Bumbleworks.launch!('i_wait_for_nobody')
      wait_until { bp.reload.tasks.count == 1 }
      bp.subscribed_events.should == []
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
    it 'returns nil if entity_fields is empty' do
      bp = described_class.new('nothing')
      bp.stub(:entity_fields => {})
      bp.entity.should be_nil
    end

    it 'returns entity provided at launch' do
      rainbow_loom = RainbowLoom.new('1234')
      bp = Bumbleworks.launch!('going_to_the_dance', :entity => rainbow_loom)
      wait_until { bp.reload.trackers.count > 0 }
      bp.entity.should == rainbow_loom
    end

    it 'bubbles EntityConflict from entity_fields' do
      bp = described_class.new('whatever')
      bp.stub(:entity_fields).and_raise(Bumbleworks::Process::EntityConflict)
      expect {
        bp.entity
      }.to raise_error(Bumbleworks::Process::EntityConflict)
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