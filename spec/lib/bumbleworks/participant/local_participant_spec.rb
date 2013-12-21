describe Bumbleworks::Participant::LocalParticipant do
  it 'includes Ruote::LocalParticipant' do
    described_class.included_modules.should include(Ruote::LocalParticipant)
  end

  it 'includes WorkitemEntityStorage' do
    described_class.included_modules.should include(Bumbleworks::WorkitemEntityStorage)
  end
end