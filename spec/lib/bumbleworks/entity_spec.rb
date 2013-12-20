describe Bumbleworks::Entity do
  let(:entity_class) { Class.new { include Bumbleworks::Entity } }

  describe '#processes' do
    it 'returns hash of process names and identifiers' do
      [:zoom, :foof, :nook].each do |pname|
        entity_class.send(:attr_accessor, :"#{pname}_pid")
        entity_class.process pname, :column => :"#{pname}_pid"
      end

      entity = entity_class.new
      entity.foof_pid = '1234'
      entity.nook_pid = 'pickles'
      entity.processes.should == {
        :zoom => nil,
        :foof => Bumbleworks::Process.new('1234'),
        :nook => Bumbleworks::Process.new('pickles')
      }
    end

    it 'returns empty hash if no processes' do
      entity_class.new.processes.should == {}
    end
  end

  describe '#cancel_all_processes!' do
    it 'cancels all processes with registered identifiers' do
      entity = entity_class.new
      bp1 = Bumbleworks::Process.new('1234')
      bp2 = Bumbleworks::Process.new('pickles')
      entity.stub(:processes).and_return({
        :zoom => nil,
        :foof => bp1,
        :nook => bp2
      })
      bp1.should_receive(:cancel!)
      bp2.should_receive(:cancel!)
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
      entity.should_receive(:update).with(:a_column => :a_value)
      entity.persist_process_identifier(:a_column, :a_value)
    end

    it 'raises exception if #update method does not exist' do
      entity = entity_class.new
      entity.stub(:respond_to?).with(:update).and_return(false)
      entity.should_receive(:update).never
      expect {
        entity.persist_process_identifier(:a_column, :a_value)
      }.to raise_error("Entity must define #persist_process_identifier method if missing #update method.")
    end
  end

  describe '#launch_process' do
    it 'launches process and return process if identifier not set' do
      bp = Bumbleworks::Process.new('12345')
      entity_class.process :noodles, :column => :noodles_pid
      entity = entity_class.new
      entity.stub(:noodles_pid)
      entity.stub(:process_fields).with(:noodles).and_return('the_fields')
      entity.stub(:process_variables).with(:noodles).and_return('the_variables')
      Bumbleworks.stub(:launch!).with('noodles', 'the_fields', 'the_variables').and_return(bp)
      entity.should_receive(:persist_process_identifier).with(:noodles_pid, '12345')
      entity.launch_process('noodles').should == bp
    end

    it 'does nothing but returns existing process if identifier column already set' do
      bp = Bumbleworks::Process.new('already set')
      entity_class.process :noodles, :column => :noodles_pid
      entity = entity_class.new
      entity.stub(:noodles_pid => 'already set')
      Bumbleworks.should_receive(:launch!).never
      entity.launch_process('noodles').should == bp
    end

    it 'launches new process anyway if identifier column already set but force is true' do
      bp = Bumbleworks::Process.new('12345')
      entity_class.process :noodles, :column => :noodles_pid
      entity = entity_class.new
      entity.stub(:noodles_pid => 'already set')
      Bumbleworks.stub(:launch! => bp)
      entity.should_receive(:persist_process_identifier).with(:noodles_pid, '12345')
      entity.launch_process('noodles', :force => true).should == bp
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

  describe '.process' do
    it 'registers a new process' do
      entity_class.stub(:process_identifier_column).with(:whatever).and_return('loob')
      entity_class.process :whatever
      entity_class.processes.should == {
        :whatever => {
          :column => 'loob'
        }
      }
    end
  end

  describe '.process_identifier_column' do
    it 'adds _process_identifier to end of given process name' do
      entity_class.process_identifier_column('zoof').should == :zoof_process_identifier
    end

    it 'ensures no duplication of _process' do
      entity_class.process_identifier_column('zoof_process').should == :zoof_process_identifier
    end

    it 'removes entity_type from beginning of identifier' do
      entity_class.stub(:entity_type).and_return('zoof')
      entity_class.process_identifier_column('zoof_process').should == :process_identifier
    end
  end

  describe '.entity_type' do
    it 'returns underscored version of class name' do
      entity_class.stub(:name).and_return('MyClass')
      entity_class.entity_type.should == 'my_class'
    end
  end
end