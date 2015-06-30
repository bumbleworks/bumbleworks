describe Bumbleworks::Entity do
  let(:entity_class) { Class.new { include Bumbleworks::Entity } }

  describe '#identifier' do
    it 'returns id by default' do
      entity = entity_class.new
      allow(entity).to receive_messages(:id => 'berf')
      expect(entity.identifier).to eq('berf')
    end
  end

  describe '#to_s' do
    it 'returns string with titleized class name and identifier' do
      allow(entity_class).to receive_messages(:name => 'GiantAngryPlum')
      entity = entity_class.new
      allow(entity).to receive_messages(:identifier => 1490)
      expect(entity.to_s).to eq('Giant Angry Plum 1490')
    end
  end

  describe '#processes_by_name' do
    it 'returns hash of process names and process instances' do
      [:zoom, :foof, :nook].each do |pname|
        entity_class.send(:attr_accessor, :"#{pname}_pid")
        entity_class.process pname, :attribute => :"#{pname}_pid"
      end

      entity = entity_class.new
      entity.foof_pid = '1234'
      entity.nook_pid = 'pickles'
      expect(entity.processes_by_name).to eq({
        :zoom => nil,
        :foof => Bumbleworks::Process.new('1234'),
        :nook => Bumbleworks::Process.new('pickles')
      })
    end

    it 'returns empty hash if no processes' do
      expect(entity_class.new.processes_by_name).to eq({})
    end
  end

  describe '#processes' do
    it 'returns array of process instances for all running processes' do
      [:zoom, :foof, :nook].each do |pname|
        entity_class.send(:attr_accessor, :"#{pname}_pid")
        entity_class.process pname, :attribute => :"#{pname}_pid"
      end
      entity = entity_class.new
      entity.foof_pid = '1234'
      entity.nook_pid = 'pickles'
      expect(entity.processes).to match_array([
        Bumbleworks::Process.new('1234'),
        Bumbleworks::Process.new('pickles')
      ])
    end

    it 'returns empty array if no processes' do
      expect(entity_class.new.processes).to eq([])
    end
  end

  describe '#cancel_process!' do
    it 'cancels process with given name' do
      entity = entity_class.new
      allow(entity).to receive_messages(:processes_by_name => {
        :foof => bp = Bumbleworks::Process.new('1234')
      })
      expect(bp).to receive(:cancel!).with(:foo => :bar)
      allow(entity).to receive(:attribute_for_process_name).
        with(:foof).and_return(:foof_pid)
      expect(entity).to receive(:update).with(:foof_pid => nil)
      entity.cancel_process!('foof', :foo => :bar)
    end

    it 'does nothing if no process for given name' do
      entity = entity_class.new
      allow(entity).to receive_messages(:processes_by_name => {})
      expect {
        entity.cancel_process!('snord')
      }.not_to raise_error
    end

    it 'does not clear identifiers if clear_identifiers option is false' do
      entity = entity_class.new
      allow(entity).to receive_messages(:processes_by_name => {
        :foof => bp = Bumbleworks::Process.new('1234')
      })
      options = { :clear_identifiers => false, :foo => :bar }
      expect(bp).to receive(:cancel!).with(:foo => :bar)
      expect(entity).to receive(:update).never
      entity.cancel_process!(:foof, options)
    end
  end

  describe '#cancel_all_processes!' do
    it 'cancels all processes' do
      entity = entity_class.new
      allow(entity).to receive_messages(:processes_by_name => {
        :foof => bp1 = Bumbleworks::Process.new('1234'),
        :nook => bp2 = Bumbleworks::Process.new('pickles'),
        :thulf => nil
      })
      expect(entity).to receive(:cancel_process!).with(:foof, :the_options)
      expect(entity).to receive(:cancel_process!).with(:nook, :the_options)
      expect(entity).to receive(:cancel_process!).with(:thulf, :the_options)
      entity.cancel_all_processes!(:the_options)
    end
  end

  describe '#process_fields' do
    it 'returns hash with entity' do
      entity = entity_class.new
      expect(entity.process_fields).to eq({ :entity => entity })
    end

    it 'accepts but ignores process name argument' do
      entity = entity_class.new
      expect(entity.process_fields('ignore_me')).to eq({ :entity => entity })
    end
  end

  describe '#process_variables' do
    it 'returns empty hash' do
      expect(entity_class.new.process_variables).to eq({})
    end

    it 'accepts but ignores process name argument' do
      expect(entity_class.new.process_variables('ignore me')).to eq({})
    end
  end

  describe '#persist_process_identifier' do
    it 'calls #update if method exists' do
      entity = entity_class.new
      expect(entity).to receive(:update).with(:a_attribute => :a_value)
      entity.persist_process_identifier(:a_attribute, :a_value)
    end

    it 'raises exception if #update method does not exist' do
      entity = entity_class.new
      expect {
        entity.persist_process_identifier(:a_attribute, :a_value)
      }.to raise_error("Entity must define #persist_process_identifier method if missing #update method.")
    end
  end

  describe '#launch_process' do
    it 'launches process and return process if identifier not set' do
      bp = Bumbleworks::Process.new('12345')
      entity_class.process :noodles, :attribute => :noodles_pid
      entity = entity_class.new
      allow(entity).to receive(:noodles_pid)
      allow(entity).to receive(:process_fields).with(:noodles).and_return({:f => 1})
      allow(entity).to receive(:process_variables).with(:noodles).and_return({:v => 2})
      allow(Bumbleworks).to receive(:launch!).with('noodles', {:f => 1}, {:v => 2}).and_return(bp)
      expect(entity).to receive(:persist_process_identifier).with(:noodles_pid, '12345')
      expect(entity.launch_process('noodles')).to eq(bp)
    end

    it 'does nothing but returns existing process if identifier attribute already set' do
      bp = Bumbleworks::Process.new('already set')
      entity_class.process :noodles, :attribute => :noodles_pid
      entity = entity_class.new
      allow(entity).to receive_messages(:noodles_pid => 'already set')
      expect(Bumbleworks).to receive(:launch!).never
      expect(entity.launch_process('noodles')).to eq(bp)
    end

    it 'launches new process anyway if identifier attribute already set but force is true' do
      bp = Bumbleworks::Process.new('12345')
      entity_class.process :noodles, :attribute => :noodles_pid
      entity = entity_class.new
      allow(entity).to receive_messages(:noodles_pid => 'already set')
      allow(Bumbleworks).to receive_messages(:launch! => bp)
      expect(entity).to receive(:persist_process_identifier).with(:noodles_pid, '12345')
      expect(entity.launch_process('noodles', :force => true)).to eq(bp)
    end

    it 'sends additional fields and variables to launch' do
      entity_class.process :noodles, :attribute => :noodles_pid
      entity = entity_class.new
      allow(entity).to receive(:noodles_pid)
      allow(entity).to receive(:persist_process_identifier)
      expect(Bumbleworks).to receive(:launch!).with(
        'noodles',
        { :entity => entity, :drink => 'apathy smoothie', :berry => 'black' },
        { :so_you_said => :well_so_did_i }
      ).and_return(Bumbleworks::Process.new(1))
      entity.launch_process(:noodles,
        :fields => { :drink => 'apathy smoothie', :berry => 'black' },
        :variables => { :so_you_said => :well_so_did_i }
      )
    end
  end

  describe '#attribute_for_process_name' do
    it 'returns attribute set for given process' do
      allow(entity_class).to receive(:processes).and_return({
        :goose => { :attribute => :goose_pid },
        :the_punisher => { :attribute => :your_skin }
      })
      entity = entity_class.new
      expect(entity.attribute_for_process_name(:goose)).to eq(:goose_pid)
      expect(entity.attribute_for_process_name(:the_punisher)).to eq(:your_skin)
    end

    it 'raises exception if no process found for given name' do
      allow(entity_class).to receive(:processes).and_return({
        :goose => { :attribute => :goose_pid },
      })
      entity = entity_class.new
      expect {
        entity.attribute_for_process_name(:the_punisher)
      }.to raise_error(Bumbleworks::Entity::ProcessNotRegistered, "the_punisher")
    end
  end

  describe '#subscribed_events' do
    it 'returns aggregate of subscribed events from all processes' do
      bp1 = double('bp1', :subscribed_events => ['chewing', 'popping', 'yakking'])
      bp2 = double('bp2', :subscribed_events => ['moon', 'yakking'])
      entity = entity_class.new
      allow(entity).to receive(:processes).and_return({
        :zip => bp1,
        :yip => bp2
      })
      expect(entity.subscribed_events).to match_array(['chewing', 'moon', 'popping', 'yakking'])
    end
  end

  describe '#is_waiting_for?' do
    it 'returns true if any processes are waiting for event' do
      bp1 = double('bp1', :subscribed_events => ['chewing', 'popping', 'yakking'])
      bp2 = double('bp2', :subscribed_events => ['moon', 'yakking'])
      entity = entity_class.new
      allow(entity).to receive(:processes).and_return({
        :zip => bp1,
        :yip => bp2
      })
      expect(entity.is_waiting_for?('chewing')).to be_truthy
      expect(entity.is_waiting_for?('yakking')).to be_truthy
      expect(entity.is_waiting_for?(:moon)).to be_truthy
      expect(entity.is_waiting_for?('fruiting')).to be_falsy
    end
  end

  describe '#tasks' do
    it 'returns task query for all entity tasks by default' do
      entity = entity_class.new
      allow(Bumbleworks::Task).to receive(:for_entity).with(entity).and_return(:full_task_query)
      expect(entity.tasks).to eq(:full_task_query)
    end

    it 'filters task query by nickname if provided' do
      entity = entity_class.new
      task_finder = double('task_finder')
      allow(task_finder).to receive(:by_nickname).with(:smooface).and_return(:partial_task_query)
      allow(Bumbleworks::Task).to receive(:for_entity).with(entity).and_return(task_finder)
      expect(entity.tasks(:smooface)).to eq(:partial_task_query)
    end
  end

  describe '.process' do
    it 'registers a new process' do
      allow(entity_class).to receive(:default_process_identifier_attribute).with(:whatever).and_return('loob')
      entity_class.process :whatever
      expect(entity_class.processes).to eq({
        :whatever => {
          :attribute => 'loob'
        }
      })
    end
  end

  describe '.processes' do
    it 'returns empty hash if no registered processes' do
      expect(entity_class.processes).to eq({})
    end
  end

  describe '.default_process_identifier_attribute' do
    it 'adds _process_identifier to end of given process name' do
      expect(entity_class.default_process_identifier_attribute('zoof')).to eq(:zoof_process_identifier)
    end

    it 'ensures no duplication of _process' do
      expect(entity_class.default_process_identifier_attribute('zoof_process')).to eq(:zoof_process_identifier)
    end

    it 'removes entity_type from beginning of identifier' do
      allow(entity_class).to receive(:entity_type).and_return('zoof')
      expect(entity_class.default_process_identifier_attribute('zoof_process')).to eq(:process_identifier)
    end
  end

  describe '.entity_type' do
    it 'returns underscored version of class name' do
      allow(entity_class).to receive(:name).and_return('MyClass')
      expect(entity_class.entity_type).to eq('my_class')
    end
  end
end