describe Bumbleworks::Worker::Info do
  let(:context) { Bumbleworks.dashboard.context }
  let(:proxy) {
    Bumbleworks::Worker::Proxy.new(
      'class' => :f_class,
      'pid' => :f_pid,
      'name' => :f_name,
      'id' => :f_id,
      'state' => :f_state,
      'ip' => :f_ip,
      'hostname' => :f_hostname,
      'system' => :f_system,
      'launched_at' => :f_launched_at
    )
  }
  subject { described_class.new(proxy) }

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
        'class' => :f_class,
        'pid' => :f_pid,
        'name' => :f_name,
        'id' => :f_id,
        'state' => :f_state,
        'ip' => :f_ip,
        'hostname' => :f_hostname,
        'system' => :f_system,
        'launched_at' => :f_launched_at
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
          with({ 'foo' => 1, 'id' => 'f_id' }).and_return(:foo_info)
        expect(described_class['f_id']).to eq(:foo_info)
      end
    end

    describe '.all' do
      it 'converts raw hash into info instances' do
        allow(described_class).to receive(:from_hash).
          with({ 'foo' => 1, 'id' => 'f_id'}).and_return(:foo_info)
        allow(described_class).to receive(:from_hash).
          with({ 'bar' => 1, 'id' => 'b_id'}).and_return(:bar_info)
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
        :f_id => :foo_hash,
        :b_id => :bar_hash
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

  describe "#stalling?" do
    it "returns inverse of #responding?" do
      allow(subject).to receive(:responding?).and_return(true)
      expect(subject).not_to be_stalling
      allow(subject).to receive(:responding?).and_return(false)
      expect(subject).to be_stalling
    end
  end
end