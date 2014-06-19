describe Bumbleworks::LocalParticipant do
  let(:fake_local_participant) {
    Class.new {
      include Bumbleworks::LocalParticipant
      attr_reader :workitem
      def initialize(workitem)
        @workitem = workitem
      end
    }
  }

  it 'includes Ruote::LocalParticipant' do
    expect(described_class.included_modules).to include(Ruote::LocalParticipant)
  end

  it_behaves_like "an entity holder" do
    let(:holder) { fake_local_participant.new(:a_workitem) }
    let(:storage_workitem) { Bumbleworks::Workitem.new(:a_workitem) }
  end
end