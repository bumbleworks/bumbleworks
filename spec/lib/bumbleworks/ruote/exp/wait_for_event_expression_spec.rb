describe Ruote::Exp::WaitForEventExpression do
  before :each do
    Bumbleworks.start_worker!
    Bumbleworks.dashboard.add_service('tracer', @tracer = Tracer.new)
  end

  it 'waits for event' do
    Bumbleworks.define_process 'waiter' do
      concurrence :wait_for => 2 do
        sequence do
          wait_for_event :nothing_ever_happens_to_me
          echo 'nothing'
        end
        sequence do
          wait_for_event :yay_it_happened
          echo 'yay'
        end
        sequence do
          wait_for_event /^yay/
          noop
          echo 'yay2'
        end
      end
    end

    Bumbleworks.define_process 'sender' do
      echo 'get ready', :tag => 'not yet'
      echo 'oh my gosh almost there'
      echo 'hello', :tag => 'yay_it_happened'
    end

    waiter = Bumbleworks.launch!('waiter')
    sender = Bumbleworks.launch!('sender')
    Bumbleworks.dashboard.wait_for(waiter.wfid)
    expect(@tracer).to eq(['get ready', 'oh my gosh almost there', 'hello', 'yay', 'yay2'])
  end

  it 'checks where clause' do
    Bumbleworks.define_process 'waiter' do
      wait_for_event :the_event, :where => '${this:special} == ${event:special}'
      echo 'specials! ${f:special}'
    end

    Bumbleworks.define_process 'sender' do
      noop :tag => 'the_event'
    end

    waiter1 = Bumbleworks.launch!('waiter', 'special' => 1)
    waiter2 = Bumbleworks.launch!('waiter', 'special' => 2)
    waiter3 = Bumbleworks.launch!('waiter', 'special' => 3)
    sender1 = Bumbleworks.launch!('sender', 'not_special' => 1)
    sender2 = Bumbleworks.launch!('sender', 'special' => 3)

    Bumbleworks.dashboard.wait_for(waiter3.wfid)
    expect(@tracer).to eq(['specials! 3'])
  end

  it 'checks entity match' do
    Bumbleworks.define_process 'waiter' do
      wait_for_event :the_event, :where => :entities_match
      echo 'entities! ${f:entity_type},${f:entity_id}'
    end

    Bumbleworks.define_process 'sender' do
      noop :tag => 'the_event'
    end

    waiter1 = Bumbleworks.launch!('waiter', 'entity_type' => 'Pigeon', 'entity_id' => '43-4boof')
    waiter2 = Bumbleworks.launch!('waiter', 'entity_type' => 'Rhubarb', 'entity_id' => '13-6zoop')
    waiter3 = Bumbleworks.launch!('waiter', 'entity_type' => 'Rhubarb', 'entity_id' => 'spitpickle-4boof')
    sender1 = Bumbleworks.launch!('sender', 'entity_type' => 'Pigeon', 'entity_id' => '13-6zoop')
    sender2 = Bumbleworks.launch!('sender', 'entity_type' => 'Rhubarb', 'entity_id' => 'spitpickle-4boof')

    Bumbleworks.dashboard.wait_for(waiter3.wfid)
    expect(@tracer).to eq(['entities! Rhubarb,spitpickle-4boof'])
  end

  it 'appends entity info to expected tag when :for_entity is true' do
    Bumbleworks.define_process 'waiter' do
      wait_for_event :the_event, :for_entity => true
      echo 'i found your tag, sucka'
    end

    Bumbleworks.define_process 'sender' do
      noop :tag => 'the_event__for_entity__fun_face_yellow5'
    end

    waiter = Bumbleworks.launch!('waiter', 'entity_type' => 'FunFace', 'entity_id' => 'yellow5')
    sender = Bumbleworks.launch!('sender')

    Bumbleworks.dashboard.wait_for(waiter.wfid)
    expect(@tracer).to eq(['i found your tag, sucka'])
  end
end