require File.expand_path(File.join(fixtures_path, 'schedules'))

describe Bumbleworks::Schedule do
  let(:fake_schedule) { fake_schedules.first }
  subject { described_class.new(fake_schedule) }

  before(:each) do
    allow(Bumbleworks.dashboard).to receive_messages(:schedules => fake_schedules)
  end

  it_behaves_like "comparable" do
    subject { described_class.new({ '_id' => 'fooz'}) }
    let(:other) { described_class.new({ '_id' => 'barn'}) }
  end

  describe '.all' do
    it 'returns instances for each schedule in system' do
      schedules = described_class.all
      expect(schedules.all? { |t| t.class == Bumbleworks::Schedule }).to be_truthy
      expect(schedules.map(&:id)).to match_array([
        "at-0_0!d65a8006da6d9025d48fa916071a6dc1!20140710-1001-dirisoma-rebadihe-20140718000000",
        "cron-0_0!48ec5a9db7d4c61da0ebaa968bd552c3!20140710-1016-nodemika-kudatsufu-20140710101857",
        "cron-0_0!9103b81d6b2cc198ec44b1c7c6461d1e!20140710-1023-dobabako-jabufuso-20140713111500"
      ])
    end
  end

  describe '.count' do
    it 'returns count of current schedules' do
      expect(described_class.count).to eq 3
    end
  end

  describe '.new' do
    it 'sets schedule id and fetches original_hash from dashboard' do
      expect(subject.id).to eq(fake_schedule['_id'])
      expect(subject.original_hash).to eq(fake_schedule)
    end
  end

  describe '#wfid' do
    it 'returns wfid from original hash' do
      expect(subject.wfid).to eq(fake_schedule['wfid'])
    end
  end

  describe '#process' do
    it 'returns process for wfid stored in msg' do
      expect(subject.process).to eq(Bumbleworks::Process.new(fake_schedule['wfid']))
    end
  end

  describe '#expression' do
    it 'returns expression that triggered the schedule' do
      allow(Bumbleworks::Expression).to receive(:from_fei).
        with(:a_flow_expression).and_return(:the_expression)
      expect(subject.expression).to eq(:the_expression)
    end
  end

  describe '#repeating?' do
    ['every', 'cron'].each do |exp_name|
      it "returns true if expression is '#{exp_name}'" do
        allow(subject).to receive(:expression).and_return(
          double(Bumbleworks::Expression, :tree => [exp_name]))
        expect(subject.repeating?).to be_truthy
      end
    end

    ['once', 'as_soon_as', 'when'].each do |exp_name|
      it "returns false if expression is '#{exp_name}'" do
        allow(subject).to receive(:expression).and_return(
          double(Bumbleworks::Expression, :tree => [exp_name]))
        expect(subject.repeating?).to be_falsy
      end
    end
  end

  describe '#once?' do
    it 'returns inverse of #repeating?' do
      allow(subject).to receive_messages(:repeating? => true)
      expect(subject.once?).to be_falsy
      allow(subject).to receive_messages(:repeating? => false)
      expect(subject.once?).to be_truthy
    end
  end

  describe '#next_at' do
    it 'returns time of next iteration' do
      expect(subject.next_at).to eq(Time.parse('2014-07-18 04:00:00 UTC'))
    end
  end

  describe '#original_plan' do
    it 'returns original schedule plan' do
      expect(subject.original_plan).to eq("2014-07-18 04:00:00")
      second_fake_schedule = described_class.new(fake_schedules[1])
      expect(second_fake_schedule.original_plan).to eq("1m")
    end
  end

  describe '#test_clause' do
    it 'returns test clause from expression' do
      allow(subject).to receive_messages(
        :expression => double(Bumbleworks::Expression, :tree => ['once', {'test' => 'pigeons'}, []]))
      expect(subject.test_clause).to eq('pigeons')
    end

    it 'returns nil when expression does not include test clause' do
      allow(subject).to receive_messages(
        :expression => double(Bumbleworks::Expression, :tree => ['once', {}, []]))
      expect(subject.test_clause).to be_nil
    end
  end
end
