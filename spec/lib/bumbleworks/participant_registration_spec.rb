describe Bumbleworks::ParticipantRegistration do
  before(:each) do
    Bumbleworks.root = File.join(fixtures_path, 'apps', 'with_default_directories')
  end

  describe '.autoload_all' do
    it 'autoloads all participants in directory' do
      Object.should_receive(:autoload).with(:HoneyParticipant,
        File.join(Bumbleworks.root, 'participants', 'honey_participant.rb'))
      Object.should_receive(:autoload).with(:MolassesParticipant,
        File.join(Bumbleworks.root, 'participants', 'molasses_participant.rb'))
      described_class.autoload_all
    end

    it 'does nothing if using default path and directory does not exist' do
      Bumbleworks.root = File.join(fixtures_path, 'apps', 'minimal')
      described_class.autoload_all
    end

    it 'raises exception if using custom path and participants file does not exist' do
      Bumbleworks.participants_directory = 'oysters'
      expect {
        described_class.autoload_all
      }.to raise_error(Bumbleworks::InvalidSetting)
    end
  end

  describe '.register!' do
    it 'loads registration file' do
      Kernel.should_receive(:load).with(File.join(Bumbleworks.root, 'participants.rb'))
      described_class.register!
    end

    it 'registers default participants if using default path and file does not exist' do
      Bumbleworks.root = File.join(fixtures_path, 'apps', 'minimal')
      Bumbleworks.should_receive(:register_default_participants)
      described_class.register!
    end

    it 'raises exception if using custom path and participants file does not exist' do
      Bumbleworks.participant_registration_file = 'oysters'
      expect {
        described_class.register!
      }.to raise_error(Bumbleworks::InvalidSetting)
    end
  end
end