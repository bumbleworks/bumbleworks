describe Bumbleworks::ErrorHandler do
  subject {described_class.new(workitem)}
  let(:workitem) { double }
  describe '#initialize' do
    it 'sets workitem' do
      subject.workitem.should == workitem
    end
  end

  describe '#on_error' do
    it 'raises a SubclassResponsiblity exception' do
      expect{subject.on_error}.to raise_error Bumbleworks::ErrorHandler::SubclassResponsibility
    end
  end
end
