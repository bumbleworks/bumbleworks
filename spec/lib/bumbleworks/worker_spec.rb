require 'pry'

describe Bumbleworks::Worker do
  let(:context) { Bumbleworks.dashboard.context }
  subject { described_class.new(context) }

  it 'is a Ruote::Worker' do
    expect(subject).to be_a(Ruote::Worker)
  end

  describe '.new' do
    it 'saves the worker info to a storage variable' do
      subject
      workers = Bumbleworks.dashboard.worker_info
      expect(workers.count).to eq(1)
      expect(workers.keys.first).to eq(subject.id)
    end
  end

  describe '.change_worker_state' do
    let!(:workers) {
      2.times.map { |i|
        worker = described_class.new(context)
        worker.run_in_thread
        worker
      }
    }

    it 'changes state of all workers' do
      expect(workers.map(&:state)).to eq(['running', 'running'])
      described_class.change_worker_state('paused')
      wait_until { workers.all? { |w| w.state == 'paused' } }
    end

    it 'times out if worker states not changed in time' do
      # Stub setting of worker state so workers are never stopped
      allow(Bumbleworks.dashboard).to receive(:worker_state=)
      expect {
        described_class.change_worker_state('paused', :timeout => 0)
      }.to raise_error(described_class::WorkerStateNotChanged)
    end
  end

  describe '.shutdown_all' do
    it 'changes all worker states to stopped' do
      expect(described_class).to receive(:change_worker_state).with('stopped', {})
      described_class.shutdown_all
    end
  end

  describe '.pause_all' do
    it 'changes all worker states to paused' do
      expect(described_class).to receive(:change_worker_state).with('paused', {})
      described_class.pause_all
    end
  end

  describe '.unpause_all' do
    it 'changes all worker states to running' do
      expect(described_class).to receive(:change_worker_state).with('running', {})
      described_class.unpause_all
    end
  end

  describe '#id' do
    it 'returns generated uuid' do
      allow(SecureRandom).to receive(:uuid).and_return('smokeeeeys')
      expect(subject.id).to eq('smokeeeeys')
    end
  end
end