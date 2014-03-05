require File.expand_path(File.join(fixtures_path, 'participants', 'naughty_participant'))

describe Bumbleworks::Process::ErrorRecord do
  before :each do
    Bumbleworks::Ruote.register_participants do
      fall_apart NaughtyParticipant
    end
    Bumbleworks.start_worker!

    Bumbleworks.define_process 'a_pain_in_the_tush' do
      fall_apart
    end
    @process = Bumbleworks.launch!('a_pain_in_the_tush')
    wait_until { @process.reload.errors.count == 1 }
    @error = @process.errors.first
  end

  describe '#error_class_name' do
    it 'returns the class name of the recorded error (as a string)' do
      expect(@error.error_class_name).to eq 'NaughtyParticipant::StupidError'
    end
  end

  describe '#backtrace' do
    it 'returns the recorded error backtrace as array of strings' do
      expect(@error.backtrace).to be_an Array
      expect(@error.backtrace.first).to match(/in `on_workitem'$/)
    end
  end

  describe '#fei' do
    it 'returns the fei from when the error occurred' do
      fei = @error.fei
      expect(fei.wfid).to eq @process.wfid
      expect(fei.expid).to eq '0_0'
    end
  end

  describe '#message' do
    it 'returns the original error message' do
      expect(@error.message).to eq 'Oh crumb.'
    end
  end

  describe '#reify' do
    it 're-instantiates the original exception' do
      original_error = @error.reify
      expect(original_error).to be_a NaughtyParticipant::StupidError
      expect(original_error.backtrace).to eq @error.backtrace
      expect(original_error.message).to eq @error.message
    end

    it 'raises exception if exception class not defined' do
      @error.instance_variable_get(:@process_error).h['class'] = 'Goose'
      expect {
        @error.reify
      }.to raise_error(NameError, 'uninitialized constant Goose')
    end
  end
end