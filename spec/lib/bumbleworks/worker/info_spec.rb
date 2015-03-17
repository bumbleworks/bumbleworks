describe Bumbleworks::Worker::Info do
  let(:context) { Bumbleworks.dashboard.context }
  let(:proxy) {
    Bumbleworks::Worker::Proxy.new(
      "class" => "f_class",
      "pid" => "f_pid",
      "name" => "f_name",
      "id" => "f_id",
      "state" => "f_state",
      "ip" => "f_ip",
      "hostname" => "f_hostname",
      "system" => "f_system",
      "uptime" => "f_uptime",
      "launched_at" => "2010-10-10 10:10:10"
    )
  }
  subject { described_class.new(proxy) }


  describe "delegation to hash" do
    let(:raw_hash) {
      {
        "processed_last_minute" => 20,
        "wait_time_last_minute" => 300.5,
        "processed_last_hour" => 540,
        "wait_time_last_hour" => 15.6
      }
    }
    before(:each) do
      allow(subject).to receive(:raw_hash).and_return(raw_hash)
    end

    it { is_expected.to fetch(:processed_last_minute).from(raw_hash) }
    it { is_expected.to fetch(:wait_time_last_minute).from(raw_hash) }
    it { is_expected.to fetch(:processed_last_hour).from(raw_hash) }
    it { is_expected.to fetch(:wait_time_last_hour).from(raw_hash) }
  end

  describe "delegation to worker/proxy" do
    it { is_expected.to delegate(:id).to(proxy) }
    it { is_expected.to delegate(:pid).to(proxy) }
    it { is_expected.to delegate(:name).to(proxy) }
    it { is_expected.to delegate(:state).to(proxy) }
    it { is_expected.to delegate(:ip).to(proxy) }
    it { is_expected.to delegate(:hostname).to(proxy) }
    it { is_expected.to delegate(:system).to(proxy) }
    it { is_expected.to delegate(:launched_at).to(proxy) }
  end

  describe '.raw_hash' do
    it 'returns Bumbleworks.dashboard.worker_info' do
      allow(Bumbleworks.dashboard).to receive(:worker_info).and_return(:bontron)
      expect(described_class.raw_hash).to eq(:bontron)
    end

    it 'returns empty hash if worker_info is nil' do
      allow(Bumbleworks.dashboard).to receive(:worker_info).and_return(nil)
      expect(described_class.raw_hash).to eq({})
    end
  end

  describe '.from_hash' do
    it 'returns an info object using a proxy worker with given attributes' do
      hash = {
        "class" => "f_class",
        "pid" => "f_pid",
        "name" => "f_name",
        "id" => "f_id",
        "state" => "f_state",
        "ip" => "f_ip",
        "hostname" => "f_hostname",
        "system" => "f_system",
        "uptime" => "f_uptime",
        "launched_at" => "2010-10-10 10:10:10"
      }
      allow(described_class).to receive(:new).
        with(proxy).
        and_return(:proxy)
      expect(described_class.from_hash(hash)).to eq(:proxy)
    end
  end

  context 'with fake raw hash' do
    before(:each) do
      raw_hash = {
        'f_id' => { 'foo' => 1 },
        'b_id' => { 'bar' => 1 }
      }
      allow(described_class).to receive(:raw_hash).
        and_return(raw_hash)
    end

    describe '.[]' do
      it 'calls from_hash with raw data for given worker id' do
        allow(described_class).to receive(:from_hash).
          with({ 'foo' => 1 }).and_return(:foo_info)
        expect(described_class['f_id']).to eq(:foo_info)
      end
    end

    describe '.all' do
      it 'converts raw hash into info instances' do
        allow(described_class).to receive(:from_hash).
          with({ 'foo' => 1 }).and_return(:foo_info)
        allow(described_class).to receive(:from_hash).
          with({ 'bar' => 1 }).and_return(:bar_info)
        expect(described_class.all).to match_array([:foo_info, :bar_info])
      end
    end
  end

  context 'with multiple workers' do
    let!(:workers) {
      3.times.map { |i|
        worker = Bumbleworks::Worker.new(context)
        worker.run_in_thread
        worker
      }
    }

    describe '.filter' do
      it 'returns info objects for workers that pass given block' do
        expect(described_class.filter { |worker|
          worker.id != workers[0].id
        }).to match_array([
          described_class[workers[1].id],
          described_class[workers[2].id]
        ])
      end
    end

    describe '.where' do
      it 'returns info objects for workers that match given criteria' do
        expect(described_class.where(:id => workers[0].id)).
          to match_array([described_class[workers[0].id]])
      end
    end

    describe '.forget_worker' do
      it 'deletes worker info for given worker id' do
        described_class.forget_worker(workers[1].id)
        expect(described_class.raw_hash.keys).not_to include(workers[1].id)
      end
    end

    describe '.purge_stale_worker_info' do
      it 'deletes all worker info where state is stopped or nil' do
        workers[0].shutdown
        workers[1].instance_variable_set(:@state, nil)
        workers[1].instance_variable_get(:@info).save
        remaining_worker_info = described_class[workers[2].id]
        described_class.purge_stale_worker_info
        expect(described_class.all).to eq([remaining_worker_info])
      end

      it 'returns without issue if no workers' do
        doc = Bumbleworks.dashboard.storage.get('variables', 'workers')
        Bumbleworks.dashboard.storage.delete(doc)
        described_class.purge_stale_worker_info
      end
    end
  end

  describe "#worker_class_name" do
    it "returns class_name from worker/proxy" do
      allow(proxy).to receive(:class_name).and_return('barkle rutfut')
      expect(subject.worker_class_name).to eq('barkle rutfut')
    end
  end

  describe "#uptime" do
    it "returns difference between now and updated_at" do
      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)
      expect(subject.uptime).to eq(frozen_time - subject.launched_at)
    end

    it "returns previous persisted uptime if stopped" do
      allow(proxy).to receive(:state).and_return("stopped")
      expect(subject.uptime).to eq(proxy.uptime)
    end
  end

  describe "#updated_at" do
    it "returns parsed put_at from raw hash for worker" do
      allow(subject).to receive(:raw_hash).and_return({
        'put_at' => '2015-10-12 11:15:30'
      })
      expect(subject.updated_at).to eq(Time.parse('2015-10-12 11:15:30'))
    end
  end

  describe "#updated_since?" do
    let(:frozen_time) { Time.now }

    it "returns true if updated_at after given time" do
      allow(subject).to receive(:updated_at).and_return(frozen_time - 2)
      expect(subject).to be_updated_since(frozen_time - 3)
    end

    it "returns false if updated_at before given time" do
      allow(subject).to receive(:updated_at).and_return(frozen_time - 3)
      expect(subject).not_to be_updated_since(frozen_time - 2)
    end
  end

  describe "#updated_recently?" do
    before(:each) do
      allow(Bumbleworks).to receive(:timeout).and_return(3)
    end

    it "returns true if updated_at is no more than Bumbleworks.timeout seconds ago" do
      allow(subject).to receive(:updated_at).and_return(Time.now - 2)
      expect(subject).to be_updated_recently
    end

    it "returns false if updated_at is more than Bumbleworks.timeout seconds ago" do
      allow(subject).to receive(:updated_at).and_return(Time.now - 4)
      expect(subject).not_to be_updated_recently
    end

    it "allows override of how many seconds ago" do
      allow(subject).to receive(:updated_at).and_return(Time.now - 15)
      expect(subject).to be_updated_recently(seconds_ago: 20)
    end
  end

  describe "#raw_hash" do
    it "returns value from worker_info hash at key of worker id" do
      allow(described_class).to receive(:raw_hash).and_return({
        "f_id" => :foo_hash,
        "b_id" => :bar_hash
      })
      expect(subject.raw_hash).to eq(:foo_hash)
    end
  end

  describe "#responding?" do
    it "returns true if updated_recently? returns true in time" do
      allow(subject).to receive(:updated_since?).and_return(true)
      expect(subject).to be_responding
    end

    it "returns false if updated_recently? does not return true in time" do
      allow(subject).to receive(:updated_since?).and_raise(Bumbleworks::Support::WaitTimeout)
      expect(subject).not_to be_responding
    end
  end

  describe "#in_stopped_state?" do
    it "returns true if state is stopped" do
      allow(proxy).to receive(:state).and_return("stopped")
      expect(subject).to be_in_stopped_state
    end

    it "returns true if state is stalled" do
      allow(proxy).to receive(:state).and_return("stalled")
      expect(subject).to be_in_stopped_state
    end

    it "returns true if state is nil" do
      allow(proxy).to receive(:state).and_return(nil)
      expect(subject).to be_in_stopped_state
    end

    it "returns false if state is running" do
      allow(proxy).to receive(:state).and_return("running")
      expect(subject).not_to be_in_stopped_state
    end
  end

  describe "#stalling?" do
    it "returns inverse of #responding?" do
      allow(subject).to receive(:responding?).and_return(true)
      expect(subject).not_to be_stalling
      allow(subject).to receive(:responding?).and_return(false)
      expect(subject).to be_stalling
    end
  end

  context "worker control commands" do
    subject { Bumbleworks::Worker::Info.first }
    let(:other_worker) { Bumbleworks::Worker::Info.all[1] }
    before(:each) do
      2.times { Bumbleworks.start_worker! }
    end

    describe "#shutdown" do
      it "shuts down just this worker" do
        subject.shutdown
        expect(subject.state).to eq("stopped")
        expect(other_worker.state).to eq("running")
      end
    end

    describe "#pause" do
      it "pauses just this worker" do
        subject.pause
        expect(subject.state).to eq("paused")
        expect(other_worker.state).to eq("running")
      end
    end

    describe "#unpause" do
      it "unpauses just this worker" do
        [subject, other_worker].map(&:pause)
        subject.unpause
        expect(subject.state).to eq("running")
        expect(other_worker.state).to eq("paused")
      end
    end

    describe "#run" do
      it "is an alias for unpause" do
        expect(subject.method(:run)).to eq(subject.method(:unpause))
      end
    end
  end

  describe "#reload" do
    it "generates a new proxy from the current raw hash" do
      Bumbleworks.start_worker!
      subject = Bumbleworks::Worker::Info.first
      expect(Bumbleworks::Worker::Proxy).to receive(:new).
        with(subject.raw_hash).and_return(:a_worker)
      subject.reload
      expect(subject.worker).to eq(:a_worker)
    end
  end

  describe "#record_new_state" do
    it "saves new state" do
      expect(subject.worker).to receive(:state=).with("an awesome state").ordered
      expect(subject).to receive(:save).ordered
      subject.record_new_state("an awesome state")
    end
  end

  describe "#save" do
    before(:each) { Bumbleworks.start_worker! }
    subject { Bumbleworks::Worker::Info.first }

    it "persists all data unchanged to the engine storage" do
      expected_hash = subject.constant_worker_info_hash
      subject.save
      expect(described_class[subject.id.to_s].constant_worker_info_hash).to eq(expected_hash)
    end

    it "updates uptime and updated_at even without changed data" do
      uptime, updated_at = subject.uptime, subject.updated_at
      subject.save
      expect(described_class[subject.id.to_s].uptime).not_to eq(uptime)
      expect(described_class[subject.id.to_s].updated_at).not_to eq(updated_at)
    end

    it "persists changed data" do
      expected_hash = subject.constant_worker_info_hash
      subject.worker.instance_variable_set(:@pid, "12345")
      subject.save
      expect(described_class[subject.id.to_s].id).to eq(expected_hash["id"])
      expect(described_class[subject.id.to_s].pid).to eq("12345")
    end

    it "does not update uptime if worker is stopped" do
      allow_any_instance_of(Bumbleworks::Worker::Proxy).to receive(:state).
        and_return("stopped")
      uptime = subject.uptime
      subject.save
      expect(described_class[subject.id.to_s].uptime).to eq(uptime)
    end
  end
end