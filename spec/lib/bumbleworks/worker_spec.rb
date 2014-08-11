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

  context 'with multiple workers' do
    let!(:workers) {
      2.times.map { |i|
        worker = described_class.new(context)
        worker.run_in_thread
        worker
      }
    }

    describe '.worker_states' do
      it 'returns the states of all active workers' do
        subject.run_in_thread
        expect(described_class.worker_states).to eq({
          subject.id => 'running',
          workers[0].id => 'running',
          workers[1].id => 'running'
        })
      end

      it 'does not include stopped or nil states' do
        subject.run_in_thread
        workers[0].shutdown
        workers[1].instance_variable_set(:@state, nil)
        workers[1].instance_variable_get(:@info).save
        expect(described_class.worker_states).to eq({
          subject.id => 'running'
        })
      end
    end

    describe '.info' do
      it 'returns Bumbleworks.dashboard.worker_info' do
        allow(Bumbleworks.dashboard).to receive(:worker_info).and_return(:bontron)
        expect(described_class.info).to eq(:bontron)
      end
    end

    describe '.forget_worker' do
      it 'deletes worker info for given worker id' do
        described_class.forget_worker(workers[1].id)
        expect(described_class.info.keys).not_to include(workers[1].id)
      end
    end

    describe '.purge_stale_worker_info' do
      it 'deletes all worker info where state is stopped or nil' do
        subject.run_in_thread
        workers[0].shutdown
        workers[1].instance_variable_set(:@state, nil)
        workers[1].instance_variable_get(:@info).save
        subject_info = described_class.info[subject.id]
        described_class.purge_stale_worker_info
        expect(described_class.info).to eq({
          subject.id => subject_info
        })
      end
    end

    describe '.change_worker_state' do
      it 'changes state of all workers' do
        expect(workers.map(&:state).uniq).to eq(['running'])
        described_class.change_worker_state('paused')
        expect(workers.map(&:state).uniq).to eq(['paused'])
      end

      it 'times out if worker states not changed in time' do
        # Stub setting of worker state so workers are never stopped
        allow(Bumbleworks.dashboard).to receive(:worker_state=)
        expect {
          described_class.change_worker_state('paused', :timeout => 0)
        }.to raise_error(described_class::WorkerStateNotChanged)
      end

      it 'ignores already stopped workers' do
        described_class.shutdown_all
        subject.run_in_thread
        described_class.change_worker_state('paused')
        expect(subject.state).to eq('paused')
        expect(workers.map(&:state)).to eq(['stopped', 'stopped'])
      end
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