describe Bumbleworks::Participant do
  it 'includes Bumbleworks::LocalParticipant' do
    expect(described_class.included_modules).to include(Bumbleworks::LocalParticipant)
  end

  it 'defines #on_cancel' do
    expect {
      subject.on_cancel
    }.not_to raise_error
  end
end