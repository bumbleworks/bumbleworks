describe Bumbleworks::SimpleLogger do
  before :each do
    Bumbleworks::SimpleLogger.clear!
  end

  [:info, :debug, :fatal, :warn, :error].each do |level|
    describe ".#{level}" do
      it "adds given object to the log with '#{level}' level" do
        expect(described_class).to receive(:add).
          with(level, :something => :happened)
        described_class.send(level.to_sym, :something => :happened)
      end
    end
  end

  describe '.add' do
    it 'adds given object to the log at given level' do
      described_class.add(:info, :super_serious_occurrence)
      described_class.add(:debug, :weird_thing)
      described_class.entries.should == [
        { :level => :info, :entry => :super_serious_occurrence },
        { :level => :debug, :entry => :weird_thing }
      ]
    end
  end

  describe '.entries' do
    it 'returns entries at all levels when given no filter' do
      described_class.info 'thing'
      described_class.debug 'other thing'
      described_class.info 'third thing'
      described_class.fatal 'final thing'
      described_class.entries.should == [
        { :level => :info, :entry => 'thing' },
        { :level => :debug, :entry => 'other thing' },
        { :level => :info, :entry => 'third thing' },
        { :level => :fatal, :entry => 'final thing' }
      ]
    end
  end

  describe '.clear!' do
    it 'deletes all entries' do
      described_class.entries.should be_empty
      described_class.info 'thing'
      described_class.entries.should_not be_empty
      described_class.clear!
      described_class.entries.should be_empty
    end
  end
end