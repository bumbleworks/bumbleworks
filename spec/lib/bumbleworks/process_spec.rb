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
      bp = Bumbleworks::Process.new('apples')
      bp.id.should == 'apples'
    end
  end

  describe '#wfid' do
    it 'is aliased to id' do
      bp = Bumbleworks::Process.new('smorgatoof')
      bp.wfid.should == 'smorgatoof'
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
      bp1 = Bumbleworks::Process.new('in_da_sky')
      bp2 = Bumbleworks::Process.new('in_da_sky')
      bp1.should == bp2
    end
  end
end