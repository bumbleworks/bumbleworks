describe Bumbleworks::ErrorHandler do
  subject {described_class.new(workitem)}
  let(:workitem) { double }
  describe '#initialize' do
    it 'sets workitem' do
      expect(subject.workitem).to eq(workitem)
    end
  end

  it_behaves_like "an entity holder" do
    let(:holder) { described_class.new(workitem) }
    let(:storage_workitem) { Bumbleworks::Workitem.new(workitem) }
  end

  describe '#on_error' do
    it 'raises a SubclassResponsiblity exception' do
      expect{subject.on_error}.to raise_error Bumbleworks::ErrorHandler::SubclassResponsibility
    end
  end
end
