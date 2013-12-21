describe Bumbleworks::Participant::Base do
  it 'includes Bumbleworks::Participant::LocalParticipant' do
    described_class.included_modules.should include(Bumbleworks::Participant::LocalParticipant)
  end

  it 'defines #on_cancel' do
    expect {
      subject.on_cancel
    }.not_to raise_error
  end
end