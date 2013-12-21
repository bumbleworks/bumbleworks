describe Bumbleworks::Participant do
  it 'includes Bumbleworks::LocalParticipant' do
    described_class.included_modules.should include(Bumbleworks::LocalParticipant)
  end

  it 'defines #on_cancel' do
    expect {
      subject.on_cancel
    }.not_to raise_error
  end
end