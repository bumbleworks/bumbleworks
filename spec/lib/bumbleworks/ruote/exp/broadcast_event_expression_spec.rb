describe Ruote::Exp::BroadcastEventExpression do
  before :each do
    Bumbleworks.reset!
    Bumbleworks.storage = {}
    Bumbleworks.start_worker!
    Bumbleworks.dashboard.add_service('tracer', @tracer = Tracer.new)
  end

  it 'uses attribute text as tag' do
    Bumbleworks.define_process 'waiter' do
      await :left_tag => :the_event, :global => true
      echo 'amazing'
    end

    Bumbleworks.define_process 'sender' do
      broadcast_event :the_event
    end

    waiter = Bumbleworks.launch!('waiter')
    sender = Bumbleworks.launch!('sender')
    Bumbleworks.dashboard.wait_for(waiter)
    @tracer.should == ['amazing']
  end
end