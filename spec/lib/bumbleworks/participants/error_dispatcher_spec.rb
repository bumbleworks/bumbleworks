describe Bumbleworks::ErrorDispatcher do
  describe '#on_workitem' do
    let(:workitem) { double('workitem') }
    let(:instances) { [double(:on_error => nil), double(:on_error => nil)] }
    let(:error_handlers) { [double(:new => instances[0]), double(:new => instances[1])] }

    it 'calls all error handlers passing in workitem' do
      Bumbleworks.error_handlers = error_handlers
      expect(error_handlers[0]).to receive(:new).ordered.with(workitem).and_return(instances[0])
      expect(error_handlers[1]).to receive(:new).ordered.with(workitem).and_return(instances[1])
      allow(subject).to receive_messages(:reply => nil, :workitem => workitem)
      subject.on_workitem
    end
  end
end
