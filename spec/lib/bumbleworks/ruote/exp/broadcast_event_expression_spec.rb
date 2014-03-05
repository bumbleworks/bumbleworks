describe Ruote::Exp::BroadcastEventExpression do
  before :each do
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
    Bumbleworks.dashboard.wait_for(waiter.wfid)
    @tracer.should == ['amazing']
  end

  it 'appends entity info to tag when :for_entity is true' do
    Bumbleworks.define_process 'waiter' do
      await :left_tag => :the_event__for_entity__pig_widget_15, :global => true
      echo 'amazing'
    end

    Bumbleworks.define_process 'sender' do
      broadcast_event :the_event, :for_entity => true
    end

    waiter = Bumbleworks.launch!('waiter')
    sender = Bumbleworks.launch!('sender', :entity_type => 'PigWidget', :entity_id => 15)
    Bumbleworks.dashboard.wait_for(waiter.wfid)
    @tracer.should == ['amazing']
  end
end