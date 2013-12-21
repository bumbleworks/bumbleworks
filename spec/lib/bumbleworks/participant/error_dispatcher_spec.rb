describe Bumbleworks::ErrorDispatcher do
  describe '#on_workitem' do
    let(:workitem) { double('workitem') }
    let(:instances) { [double(:on_error => nil), double(:on_error => nil)] }
    let(:error_handlers) { [double(:new => instances[0]), double(:new => instances[1])] }

    it 'calls all error handlers passing in workitem' do
      Bumbleworks.error_handlers = error_handlers
      error_handlers[0].should_receive(:new).ordered.with(workitem).and_return(instances[0])
      error_handlers[1].should_receive(:new).ordered.with(workitem).and_return(instances[1])
      subject.stub(:reply => nil, :workitem => workitem)
      subject.on_workitem
    end
  end
end
