describe Bumbleworks::ParticipantRegistration do
  describe '.autoload_all' do
    it 'autoloads all participants in directory' do
      Bumbleworks.reset!
      Bumbleworks.root = File.join(fixtures_path, 'apps', 'with_default_directories')
      Object.should_receive(:autoload).with(:HoneyParticipant,
        File.join(Bumbleworks.root, 'participants', 'honey_participant.rb'))
      Object.should_receive(:autoload).with(:MolassesParticipant,
        File.join(Bumbleworks.root, 'participants', 'molasses_participant.rb'))
      Bumbleworks::ParticipantRegistration.autoload_all
    end
  end
end