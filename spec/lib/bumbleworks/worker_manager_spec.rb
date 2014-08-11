describe Bumbleworks::WorkerManager do
  let(:context) { Bumbleworks.dashboard.context }
  let(:worker) { Bumbleworks::Worker.new(context) }
  subject { described_class.new(worker.id) }

  describe '#info' do
    it 'returns worker info' do
      expect(subject.info).to eq(Bumbleworks.dashboard.worker_info[worker.id])
    end

    it 'always grabs freshest worker info' do
      worker
      stale_worker_info = Bumbleworks.dashboard.worker_info[worker.id]
      expect(subject.info).to eq(stale_worker_info)
      worker.shutdown
      expect(subject.info).not_to eq(stale_worker_info)
      expect(subject.info).to eq(Bumbleworks.dashboard.worker_info[worker.id])
    end
  end

  describe '#system_info' do
    it 'returns system from worker info' do
      allow(subject).to receive(:info).and_return('system' => :foo)
      expect(subject.system_info).to eq(:foo)
    end
  end

  [
    :ip, :hostname, :pid, :put_at, :uptime,
    :processed_last_minute, :processed_last_hour,
    :wait_time_last_minute, :wait_time_last_hour, :state
  ].each do |method|
    describe "##{method}" do
      it 'looks up value from worker info' do
        allow(subject).to receive(:info).and_return(method.to_s => :foo)
        expect(subject.send(method)).to eq(:foo)
      end
    end
  end
end