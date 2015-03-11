require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))

describe Bumbleworks::Process do
  before :each do
    Bumbleworks::Ruote.register_participants
    Bumbleworks.start_worker!

    Bumbleworks.define_process 'food_is_an_illusion' do
      noop :tag => 'oh_boy_are_we_hungry'
      concurrence do
        admin :task => 'eat_a_hat'
        hatter :task => 'weep'
        wait '40m'
      end
    end

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
        wait '15m'
        every '20m' do
          magician :task => 'fancy_rabbit_maneuvers'
        end
      end
    end
    Bumbleworks.define_process 'i_wait_for_nobody' do
      tough_guy :task => 'blow_this_thing_wide_open'
    end
  end

  it_behaves_like "comparable" do
    subject { described_class.new('watchful_egret') }
    let(:other) { described_class.new('lets_dance_yo') }
  end

  describe '.all' do
    it 'returns sorted and filtered array of instances for all processes' do
      expect(described_class).to receive(:ids).with(:some_options).and_return([:a, :b, :c])
      expect(described_class.all(:some_options)).to eq [
        Bumbleworks::Process.new(:a),
        Bumbleworks::Process.new(:b),
        Bumbleworks::Process.new(:c)
      ]
    end
  end

  describe '.ids' do
    before(:each) do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('going_to_the_dance')
      bp3 = Bumbleworks.launch!('going_to_the_dance')
      bp4 = Bumbleworks.launch!('going_to_the_dance')
      bp5 = Bumbleworks.launch!('straightening_the_rocks')
      @sorted_processes = [bp1, bp2, bp3, bp4, bp5].sort
      wait_until { Bumbleworks.dashboard.process_wfids.count == 5 }
    end

    it 'returns all process wfids' do
      expect(described_class.ids).to eq(@sorted_processes.map(&:wfid))
    end

    it 'allows pagination options' do
      expect(described_class.ids(:limit => 2)).to eq(@sorted_processes[0, 2].map(&:wfid))
      expect(described_class.ids(:offset => 2)).to eq(@sorted_processes[2, 5].map(&:wfid))
      expect(described_class.ids(:limit => 2, :offset => 1)).to eq(@sorted_processes[1, 2].map(&:wfid))
    end

    it 'allows reverse order' do
      expect(described_class.ids(:reverse => true)).to eq(@sorted_processes.reverse.map(&:wfid))
    end

    it 'allows combined reverse and pagination' do
      expect(described_class.ids(:reverse => true, :limit => 2)).to eq(@sorted_processes.reverse[0, 2].map(&:wfid))
      expect(described_class.ids(:reverse => true, :offset => 2)).to eq(@sorted_processes.reverse[2, 5].map(&:wfid))
      expect(described_class.ids(:reverse => true, :limit => 2, :offset => 1)).to eq(@sorted_processes.reverse[1, 2].map(&:wfid))
    end
  end

  describe '.count' do
    it 'returns number of processes' do
      allow(described_class).to receive(:ids).and_return([:a, :b, :c, :d])
      expect(described_class.count).to eq(4)
    end
  end

  describe '.new' do
    it 'sets workflow id' do
      bp = described_class.new('apples')
      expect(bp.id).to eq('apples')
    end
  end

  describe '#wfid' do
    it 'is aliased to id' do
      bp = described_class.new('smorgatoof')
      expect(bp.wfid).to eq('smorgatoof')
    end
  end

  describe '#errors' do
    it 'returns all process errors as ErrorRecord instances' do
      Bumbleworks.define_process 'error_process' do
        concurrence do
          error 'first error'
          error 'second error'
        end
      end
      bp = Bumbleworks.launch!('error_process')
      Bumbleworks.dashboard.wait_for('error_intercepted')
      errors = bp.errors
      expect(errors.map(&:class).uniq).to eq([
        Bumbleworks::Process::ErrorRecord
      ])
      expect(errors.map(&:message)).to match_array([
        'first error',
        'second error'
      ])
    end
  end

  describe '#workitems' do
    it 'returns array of workitems from each leaf' do
      bp = described_class.new('chumpy')
      l1 = double(:workitem => 'w1')
      l2 = double(:workitem => 'w2')
      l3 = double(:workitem => 'w3')
      allow(bp).to receive_messages(:leaves => [l1, l2, l3])
      expect(bp.workitems).to eq(['w1','w2','w3'])
    end
  end

  it_behaves_like "an entity holder" do
    let(:entity_workitem) { Bumbleworks::Workitem.new(:fake_workitem) }
    let(:holder) {
      holder = described_class.new('nothing')
      allow(holder).to receive_messages(:entity_workitem => entity_workitem)
      holder
    }
    let(:storage_workitem) { entity_workitem }
  end

  describe '#expressions' do
    it 'returns all expressions as array of Expression instances' do
      bp = Bumbleworks.launch!('food_is_an_illusion')
      Bumbleworks.dashboard.wait_for(:admin)
      expect(bp.expressions.map(&:expid)).to eq [
        '0', '0_1', '0_1_0', '0_1_1', '0_1_2'
      ]
      expect(bp.expressions.map(&:class).uniq).to eq [
        Bumbleworks::Expression
      ]
    end
  end

  describe '#definition_name' do
    it 'returns the name of the process definition' do
      bp = Bumbleworks.launch!('i_wait_for_nobody')
      wait_until { bp.reload.tasks.count == 1 }
      bp_reloaded = described_class.new(bp.wfid)
      expect(bp_reloaded.definition_name).to eq 'i_wait_for_nobody'
    end
  end

  describe '#expression_at_position' do
    before(:each) do
      @bp = Bumbleworks.launch!('food_is_an_illusion')
      Bumbleworks.dashboard.wait_for(:admin)
    end

    it 'returns the expression whose expid matches the given position' do
      expression = @bp.expression_at_position('0_1_0')
      expect(expression).to be_a Bumbleworks::Expression
      expect(expression.expid).to eq '0_1_0'
    end

    it 'returns nil if no expression at given position' do
      expect(@bp.expression_at_position('0_2_1')).to be_nil
    end
  end

  describe '#leaves' do
    it 'returns only expressions being worked on' do
      bp = Bumbleworks.launch!('food_is_an_illusion')
      Bumbleworks.dashboard.wait_for(:admin)
      expect(bp.leaves.map(&:expid)).to eq [
        '0_1_0', '0_1_1', '0_1_2'
      ]
      expect(bp.leaves.map(&:class).uniq).to eq [
        Bumbleworks::Expression
      ]
    end
  end

  describe '#entity_workitem' do
    it 'returns first workitem from workitems array, if no entity fields conflict' do
      bp = described_class.new('nothing')
      w1 = double(:entity_fields => :some_fields)
      w2 = double(:entity_fields => :some_fields)
      allow(bp).to receive_messages(:workitems => [w1, w2])
      expect(bp.entity_workitem).to eq(w1)
    end

    it 'returns nil if no process' do
      bp = described_class.new('nothing')
      expect(bp.entity_workitem).to be_nil
    end

    it 'returns workitem with entity reference from process launch' do
      rainbow_loom = RainbowLoom.new('1234')
      bp = Bumbleworks.launch!('going_to_the_dance', :entity => rainbow_loom)
      wait_until { bp.reload.trackers.count > 0 }
      ew = bp.entity_workitem
      expect(ew.entity).to eq(rainbow_loom)
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
        bp.entity_workitem
      }.to raise_error(Bumbleworks::Process::EntityConflict)
    end
  end

  describe '#entity' do
    it 'bubbles EntityConflict from entity_workitem' do
      bp = described_class.new('whatever')
      allow(bp).to receive(:entity_workitem).and_raise(Bumbleworks::Process::EntityConflict)
      expect {
        bp.entity
      }.to raise_error(Bumbleworks::Process::EntityConflict)
    end
  end

  describe '#tasks' do
    it 'returns task query filtered for this process' do
      bp = described_class.new('chumpy')
      allow(Bumbleworks::Task).to receive(:for_process).with('chumpy').and_return(:my_task_query)
      expect(bp.tasks).to eq(:my_task_query)
    end
  end

  describe '#schedules' do
    it 'returns array of all schedules for this process' do
      bp1 = Bumbleworks.launch!('food_is_an_illusion')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.reload.schedules.count == 1 && bp2.reload.schedules.count == 2 }
      expect(bp1.schedules.map { |s| s.process }).to eq([bp1])
      expect(bp2.schedules.map { |s| s.process }).to eq([bp2, bp2])
      expect(bp1.schedules.map { |s| s.original_plan }).to eq(['40m'])
      expect(bp2.schedules.map { |s| s.original_plan }).to eq(['15m', '20m'])
      expect(bp2.schedules.map { |s| s.repeating? }).to eq([false, true])
    end
  end

  describe '#trackers' do
    it 'lists all trackers this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.reload.trackers.count == 3 && bp2.reload.trackers.count == 2 }
      expect(bp1.trackers.map { |t| t.process }).to eq([bp1, bp1, bp1])
      expect(bp2.trackers.map { |t| t.process }).to eq([bp2, bp2])
      expect(bp1.trackers.map { |t| t.action }).to eq(['left_tag', 'left_tag', 'dispatch'])
      expect(bp2.trackers.map { |t| t.action }).to eq(['left_tag', 'left_tag'])
      expect(bp1.trackers.map { |t| t.conditions['tag'] }).to eq([['an_invitation'], ['a_friend'], nil])
      expect(bp2.trackers.map { |t| t.conditions['tag'] }).to eq([['rock_caliper_delivery'], ['speedos']])
    end
  end

  describe '#all_subscribed_tags' do
    it 'lists all tags this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.reload.trackers.count == 3 && bp2.reload.trackers.count == 2 }
      expect(bp1.all_subscribed_tags).to eq({ :global => ['an_invitation'], bp1.wfid => ['a_friend'] })
      expect(bp2.all_subscribed_tags).to eq({ :global => ['rock_caliper_delivery', 'speedos'] })
    end

    it 'sets global tags to empty array by default' do
      bp = Bumbleworks.launch!('i_wait_for_nobody')
      wait_until { bp.reload.tasks.count == 1 }
      expect(bp.all_subscribed_tags).to eq({ :global => [] })
    end
  end

  describe '#subscribed_events' do
    it 'lists all events (global tags) this process is waiting on' do
      bp1 = Bumbleworks.launch!('going_to_the_dance')
      bp2 = Bumbleworks.launch!('straightening_the_rocks')
      wait_until { bp1.reload.trackers.count == 3 && bp2.reload.trackers.count == 2 }
      expect(bp1.subscribed_events).to eq(['an_invitation'])
      expect(bp2.subscribed_events).to eq(['rock_caliper_delivery', 'speedos'])
    end

    it 'returns empty array if no global tags' do
      bp = Bumbleworks.launch!('i_wait_for_nobody')
      wait_until { bp.reload.tasks.count == 1 }
      expect(bp.subscribed_events).to eq([])
    end
  end

  describe '#is_waiting_for?' do
    it 'returns true if event is in subscribed events' do
      bp = described_class.new('whatever')
      allow(bp).to receive_messages(:subscribed_events => ['ghosts', 'mouses'])
      expect(bp.is_waiting_for?('mouses')).to be_truthy
    end

    it 'converts symbolized queries' do
      bp = described_class.new('whatever')
      allow(bp).to receive_messages(:subscribed_events => ['ghosts', 'mouses'])
      expect(bp.is_waiting_for?(:ghosts)).to be_truthy
    end

    it 'returns false if event is not in subscribed events' do
      bp = described_class.new('whatever')
      allow(bp).to receive_messages(:subscribed_events => ['ghosts', 'mouses'])
      expect(bp.is_waiting_for?('organs')).to be_falsy
    end
  end

  describe '#kill!' do
    it 'kills process' do
      bp = described_class.new('frogheads')
      expect(Bumbleworks).to receive(:kill_process!).with('frogheads', :an => :option)
      bp.kill!(:an => :option)
    end
  end

  describe '#cancel!' do
    it 'cancels process' do
      bp = described_class.new('frogheads')
      expect(Bumbleworks).to receive(:cancel_process!).with('frogheads', :an => :option)
      bp.cancel!(:an => :option)
    end
  end

  describe '#==' do
    it 'returns true if other object has same wfid' do
      bp1 = described_class.new('in_da_sky')
      bp2 = described_class.new('in_da_sky')
      expect(bp1).to eq(bp2)
    end

    it 'returns false if other object is not a process' do
      bp1 = described_class.new('in_da_sky')
      bp2 = double('not a process')
      expect(bp1).not_to eq(bp2)
    end
  end

  describe '#<=>' do
    it 'compares processes by wfid' do
      bp1 = described_class.new(1)
      bp2 = described_class.new(2)
      bp3 = described_class.new(1)
      expect(bp1 <=> bp2).to eq -1
      expect(bp2 <=> bp3).to eq 1
      expect(bp3 <=> bp1).to eq 0
    end

    it 'raises ArgumentError if other object is not a process' do
      bp1 = described_class.new('in_da_sky')
      bp2 = double('not a process')
      expect { bp1 <=> bp2 }.to raise_error(ArgumentError, "comparison of Bumbleworks::Process with RSpec::Mocks::Double failed")
    end
  end

  describe '#running?' do
    it 'returns true if process_status returns something' do
      subject = described_class.new('frogheads')
      allow(subject).to receive(:process_status).and_return(:the_status)
      expect(subject.running?).to be_truthy
    end

    it 'returns false if process_status is nil' do
      subject = described_class.new('frogheads')
      allow(subject).to receive(:process_status).and_return(nil)
      expect(subject.running?).to be_falsy
    end
  end

  describe '#process_status' do
    it 'returns a process_status instance for the wfid' do
      bp = described_class.new('frogheads')
      allow(Bumbleworks.dashboard).to receive(:process).with('frogheads').and_return(:the_status)
      expect(bp.process_status).to eq(:the_status)
    end
  end

  describe '#method_missing' do
    it 'calls method on object returned by #process_status' do
      ps = double('process_status')
      allow(ps).to receive(:nuffle).with(:yay).and_return(:its_a_me)
      bp = described_class.new('frogheads')
      allow(bp).to receive_messages(:process_status => ps)
      expect(bp.nuffle(:yay)).to eq(:its_a_me)
    end

    it 'falls back to method missing if no process status method' do
      bp = described_class.new('blah')
      allow(bp).to receive_messages(:process_status => double('process status'))
      expect {
        bp.kerplunk!(:oh_no)
      }.to raise_error
    end
  end
end