describe Bumbleworks::Expression do
  let(:fei) { double({ :expid => '1_2_3', :wfid => 'snooks' }) }
  let(:fexp) { double('FlowExpression', :fei => fei, :tree => :a_tree) }
  subject { described_class.new(fexp) }

  describe '#expid' do
    it 'returns expid from fei' do
      subject.expid.should == '1_2_3'
    end
  end

  describe '#process' do
    it 'returns process for expression wfid' do
      subject.process.should == Bumbleworks::Process.new('snooks')
    end
  end

  describe '#tree' do
    it 'returns tree from flow expression' do
      expect(subject.tree).to eq :a_tree
    end
  end

  describe '#error' do
    it 'returns error from process that matches fei' do
      process = double
      process.stub(:errors => [
        double(:fei => :not_me, :message => 'alarming!'),
        double(:fei => fei, :message => 'boo!'),
        double(:fei => :also_not_me, :message => 'yippee!')
      ])
      subject.stub(:process => process)
      subject.error.message.should == 'boo!'
    end

    it 'returns nil if no error during this expression' do
      process = double
      process.stub(:errors => [
        double(:fei => :not_me, :message => 'alarming!'),
        double(:fei => :also_not_me, :message => 'yippee!')
      ])
      subject.stub(:process => process)
      subject.error.should be_nil
    end
  end

  describe '#cancel!' do
    it 'cancels the expression' do
      Bumbleworks.dashboard.should_receive(:cancel_expression).with(fei)
      subject.cancel!
    end
  end

  describe '#kill!' do
    it 'kills the expression' do
      Bumbleworks.dashboard.should_receive(:kill_expression).with(fei)
      subject.kill!
    end
  end

  describe '#workitem' do
    it 'returns the workitem as applied to this expression' do
      fexp.stub(:applied_workitem).and_return(:something_raw)
      subject.workitem.should == Bumbleworks::Workitem.new(:something_raw)
    end
  end
end
