require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))
require File.expand_path(File.join(fixtures_path, 'trackers'))

describe Bumbleworks::Tracker do
  before(:each) do
    allow(Bumbleworks.dashboard).to receive_messages(:get_trackers => fake_trackers)
  end

  describe '.all' do
    it 'returns instances for each tracker in system' do
      trackers = described_class.all
      expect(trackers.all? { |t| t.class == Bumbleworks::Tracker }).to be_truthy
      expect(trackers.map(&:id)).to match_array([
        'on_error',
        'global_tracker',
        'local_tracker',
        'local_error_intercept',
        'participant_tracker'
      ])
    end
  end

  describe '.count' do
    it 'returns count of current trackers' do
      expect(described_class.count).to eq 5
    end
  end

  describe '.new' do
    it 'sets tracker id and fetches original_hash from dashboard' do
      tr = described_class.new('global_tracker')
      expect(tr.id).to eq('global_tracker')
      expect(tr.original_hash).to eq(fake_trackers['global_tracker'])
    end

    it 'sets tracker id and original_hash if directly provided' do
      tr = described_class.new('global_tracker', 'snarfles')
      expect(tr.id).to eq('global_tracker')
      expect(tr.original_hash).to eq('snarfles')
    end
  end

  describe '#wfid' do
    it 'returns wfid from original hash' do
      expect(described_class.new('local_tracker').wfid).to eq('my_wfid')
    end

    it 'returns wfid from flow expression for global trackers' do
      expect(described_class.new('global_tracker').wfid).to eq('my_wfid')
    end

    it 'returns nil if no wfid' do
      expect(described_class.new('on_error').wfid).to be_nil
    end
  end

  describe '#process' do
    it 'returns process for wfid stored in msg' do
      tr = described_class.new('global_tracker')
      expect(tr.process).to eq(Bumbleworks::Process.new('my_wfid'))
    end

    it 'returns nil if no wfid' do
      tr = described_class.new('on_error')
      expect(tr.process).to be_nil
    end
  end

  describe '#global?' do
    it 'returns true if not listening to events on a specific wfid' do
      expect(described_class.new('on_error').global?).to be_truthy
      expect(described_class.new('global_tracker').global?).to be_truthy
    end

    it 'returns false if listening to events on a specific wfid' do
      expect(described_class.new('local_tracker').global?).to be_falsy
    end
  end

  describe '#conditions' do
    it 'returns conditions that this tracker is watching' do
      expect(described_class.new('global_tracker').conditions).to eq({ "tag" => [ "the_event" ] })
      expect(described_class.new('local_tracker').conditions).to eq({ "tag" => [ "local_event" ] })
      expect(described_class.new('local_error_intercept').conditions).to eq({ "message" => [ "/bad/" ] })
      expect(described_class.new('participant_tracker').conditions).to eq({ "participant_name" => [ "goose","bunnies" ] })
    end

    it 'returns empty hash when no conditions' do
      expect(described_class.new('on_error').conditions).to eq({})
    end
  end

  describe '#tags' do
    it 'returns array of tags' do
      expect(described_class.new('global_tracker').tags).to eq([ "the_event" ])
      expect(described_class.new('local_tracker').tags).to eq([ "local_event" ])
    end

    it 'returns empty array if no tags' do
      expect(described_class.new('local_error_intercept').tags).to eq([])
      expect(described_class.new('participant_tracker').tags).to eq([])
    end
  end

  describe '#action' do
    it 'returns action being awaited' do
      expect(described_class.new('global_tracker').action).to eq('left_tag')
      expect(described_class.new('local_error_intercept').action).to eq('error_intercepted')
      expect(described_class.new('participant_tracker').action).to eq('dispatch')
    end
  end

  describe '#waiting_expression' do
    it 'returns nil when no expression is waiting' do
      expect(described_class.new('on_error').waiting_expression).to be_nil
    end

    it 'returns expression awaiting reply' do
      process = Bumbleworks::Process.new('my_wfid')
      expression1 = double(:expid => '0_0_0', :tree => :a_global_expression)
      expression2 = double(:expid => '0_0_1', :tree => :a_local_expression)
      allow(process).to receive_messages(:expressions => [expression1, expression2])

      tracker1 = described_class.new('global_tracker')
      allow(tracker1).to receive_messages(:process => process)
      expect(tracker1.waiting_expression).to eq(:a_global_expression)

      tracker2 = described_class.new('local_tracker')
      allow(tracker2).to receive_messages(:process => process)
      expect(tracker2.waiting_expression).to eq(:a_local_expression)
    end
  end

  describe '#where_clause' do
    it 'returns where clause from waiting expression' do
      tracker = described_class.new('global_tracker')
      allow(tracker).to receive_messages(:waiting_expression => [
        'wait_for_event', { "where" => "some_stuff_matches" }, []
      ])
      expect(tracker.where_clause).to eq('some_stuff_matches')
    end

    it 'returns nil when waiting_expression does not include where clause' do
      tracker = described_class.new('global_tracker')
      allow(tracker).to receive_messages(:waiting_expression => [
        'wait_for_event', {}, []
      ])
      expect(tracker.where_clause).to be_nil
    end

    it 'returns nil when no waiting_expression' do
      expect(described_class.new('on_error').where_clause).to be_nil
    end
  end
end
