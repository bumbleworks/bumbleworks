describe Bumbleworks::Entity do
  let(:entity_class) { Class.new { include Bumbleworks::Entity } }

  describe '#processes_by_name' do
    it 'returns hash of process names and process instances' do
      [:zoom, :foof, :nook].each do |pname|
        entity_class.send(:attr_accessor, :"#{pname}_pid")
        entity_class.process pname, :attribute => :"#{pname}_pid"
      end

      entity = entity_class.new
      entity.foof_pid = '1234'
      entity.nook_pid = 'pickles'
      entity.processes_by_name.should == {
        :zoom => nil,
        :foof => Bumbleworks::Process.new('1234'),
        :nook => Bumbleworks::Process.new('pickles')
      }
    end

    it 'returns empty hash if no processes' do
      entity_class.new.processes_by_name.should == {}
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
      entity.processes.should =~ [
        Bumbleworks::Process.new('1234'),
        Bumbleworks::Process.new('pickles')
      ]
    end

    it 'returns empty array if no processes' do
      entity_class.new.processes.should == []
    end
  end

  describe '#cancel_all_processes!' do
    it 'cancels all processes with registered identifiers' do
      [:zoom, :foof, :nook].each do |pname|
        entity_class.send(:attr_accessor, :"#{pname}_pid")
        entity_class.process pname, :attribute => :"#{pname}_pid"
      end
      entity = entity_class.new
      entity.foof_pid = '1234'
      entity.nook_pid = 'pickles'
      entity.stub(:processes_by_name => {
        :foof => bp1 = Bumbleworks::Process.new('1234'),
        :nook => bp2 = Bumbleworks::Process.new('pickles')
      })
      bp1.should_receive(:cancel!)
      bp2.should_receive(:cancel!)
      entity.should_receive(:update).with(:foof_pid => nil)
      entity.should_receive(:update).with(:nook_pid => nil)
      entity.cancel_all_processes!
    end
  end

  describe '#process_fields' do
    it 'returns hash with entity' do
      entity = entity_class.new
      entity.process_fields.should == { :entity => entity }
    end

    it 'accepts but ignores process name argument' do
      entity = entity_class.new
      entity.process_fields('ignore_me').should == { :entity => entity }
    end
  end

  describe '#process_variables' do
    it 'returns empty hash' do
      entity_class.new.process_variables.should == {}
    end

    it 'accepts but ignores process name argument' do
      entity_class.new.process_variables('ignore me').should == {}
    end
  end

  describe '#persist_process_identifier' do
    it 'calls #update if method exists' do
      entity = entity_class.new
      entity.should_receive(:update).with(:a_attribute => :a_value)
      entity.persist_process_identifier(:a_attribute, :a_value)
    end

    it 'raises exception if #update method does not exist' do
      entity = entity_class.new
      entity.stub(:respond_to?).with(:update).and_return(false)
      entity.should_receive(:update).never
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
      entity.stub(:noodles_pid)
      entity.stub(:process_fields).with(:noodles).and_return({:f => 1})
      entity.stub(:process_variables).with(:noodles).and_return({:v => 2})
      Bumbleworks.stub(:launch!).with('noodles', {:f => 1}, {:v => 2}).and_return(bp)
      entity.should_receive(:persist_process_identifier).with(:noodles_pid, '12345')
      entity.launch_process('noodles').should == bp
    end

    it 'does nothing but returns existing process if identifier attribute already set' do
      bp = Bumbleworks::Process.new('already set')
      entity_class.process :noodles, :attribute => :noodles_pid
      entity = entity_class.new
      entity.stub(:noodles_pid => 'already set')
      Bumbleworks.should_receive(:launch!).never
      entity.launch_process('noodles').should == bp
    end

    it 'launches new process anyway if identifier attribute already set but force is true' do
      bp = Bumbleworks::Process.new('12345')
      entity_class.process :noodles, :attribute => :noodles_pid
      entity = entity_class.new
      entity.stub(:noodles_pid => 'already set')
      Bumbleworks.stub(:launch! => bp)
      entity.should_receive(:persist_process_identifier).with(:noodles_pid, '12345')
      entity.launch_process('noodles', :force => true).should == bp
    end

    it 'sends additional fields and variables to launch' do
      entity_class.process :noodles, :attribute => :noodles_pid
      entity = entity_class.new
      entity.stub(:noodles_pid)
      entity.stub(:persist_process_identifier)
      Bumbleworks.should_receive(:launch!).with(
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
      entity_class.stub(:processes).and_return({
        :goose => { :attribute => :goose_pid },
        :the_punisher => { :attribute => :your_skin }
      })
      entity = entity_class.new
      entity.attribute_for_process_name(:goose).should == :goose_pid
      entity.attribute_for_process_name(:the_punisher).should == :your_skin
    end

    it 'raises exception if no process found for given name' do
      entity_class.stub(:processes).and_return({
        :goose => { :attribute => :goose_pid },
      })
      entity = entity_class.new
      expect {
        entity.attribute_for_process_name(:the_punisher)
      }.to raise_error
    end
  end

  describe '#subscribed_events' do
    it 'returns aggregate of subscribed events from all processes' do
      bp1 = double('bp1', :subscribed_events => ['chewing', 'popping', 'yakking'])
      bp2 = double('bp2', :subscribed_events => ['moon', 'yakking'])
      entity = entity_class.new
      entity.stub(:processes).and_return({
        :zip => bp1,
        :yip => bp2
      })
      entity.subscribed_events.should =~ ['chewing', 'moon', 'popping', 'yakking']
    end
  end

  describe '#is_waiting_for?' do
    it 'returns true if any processes are waiting for event' do
      bp1 = double('bp1', :subscribed_events => ['chewing', 'popping', 'yakking'])
      bp2 = double('bp2', :subscribed_events => ['moon', 'yakking'])
      entity = entity_class.new
      entity.stub(:processes).and_return({
        :zip => bp1,
        :yip => bp2
      })
      entity.is_waiting_for?('chewing').should be_true
      entity.is_waiting_for?('yakking').should be_true
      entity.is_waiting_for?(:moon).should be_true
      entity.is_waiting_for?('fruiting').should be_false
    end
  end

  describe '#tasks' do
    it 'returns task query for all entity tasks by default' do
      entity = entity_class.new
      Bumbleworks::Task.stub(:for_entity).with(entity).and_return(:full_task_query)
      entity.tasks.should == :full_task_query
    end

    it 'filters task query by nickname if provided' do
      entity = entity_class.new
      task_finder = double('task_finder')
      task_finder.stub(:by_nickname).with(:smooface).and_return(:partial_task_query)
      Bumbleworks::Task.stub(:for_entity).with(entity).and_return(task_finder)
      entity.tasks(:smooface).should == :partial_task_query
    end
  end

  describe '.process' do
    it 'registers a new process' do
      entity_class.stub(:default_process_identifier_attribute).with(:whatever).and_return('loob')
      entity_class.process :whatever
      entity_class.processes.should == {
        :whatever => {
          :attribute => 'loob'
        }
      }
    end
  end

  describe '.default_process_identifier_attribute' do
    it 'adds _process_identifier to end of given process name' do
      entity_class.default_process_identifier_attribute('zoof').should == :zoof_process_identifier
    end

    it 'ensures no duplication of _process' do
      entity_class.default_process_identifier_attribute('zoof_process').should == :zoof_process_identifier
    end

    it 'removes entity_type from beginning of identifier' do
      entity_class.stub(:entity_type).and_return('zoof')
      entity_class.default_process_identifier_attribute('zoof_process').should == :process_identifier
    end
  end

  describe '.entity_type' do
    it 'returns underscored version of class name' do
      entity_class.stub(:name).and_return('MyClass')
      entity_class.entity_type.should == 'my_class'
    end
  end
end