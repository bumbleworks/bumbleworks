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

  describe '.stop_all' do
    let!(:workers) {
      2.times.map { |i|
        worker = described_class.new(context)
        worker.run_in_thread
        worker
      }
    }

    it 'stops all workers' do
      expect(workers.map(&:state)).to eq(['running', 'running'])
      described_class.stop_all
      wait_until { workers.all? { |w| w.state == 'stopped' } }
    end

    it 'times out if workers not stoppable in time' do
      # Stub setting of worker state so workers are never stopped
      allow(Bumbleworks.dashboard).to receive(:worker_state=)
      expect {
        described_class.stop_all(:timeout => 0)
      }.to raise_error(described_class::WorkersCannotBeStopped)
    end
  end

  describe '#id' do
    it 'returns generated uuid' do
      allow(SecureRandom).to receive(:uuid).and_return('smokeeeeys')
      expect(subject.id).to eq('smokeeeeys')
    end
  end
end