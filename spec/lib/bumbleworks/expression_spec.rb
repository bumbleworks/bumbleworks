describe Bumbleworks::Expression do
  let(:fei) { double({ :expid => '1_2_3', :wfid => 'snooks' }) }
  let(:fexp) { double('FlowExpression', :fei => fei, :tree => :a_tree) }
  subject { described_class.new(fexp) }

  describe '#expid' do
    it 'returns expid from fei' do
      expect(subject.expid).to eq('1_2_3')
    end
  end

  describe '#process' do
    it 'returns process for expression wfid' do
      expect(subject.process).to eq(Bumbleworks::Process.new('snooks'))
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
      allow(process).to receive_messages(:errors => [
        double(:fei => :not_me, :message => 'alarming!'),
        double(:fei => fei, :message => 'boo!'),
        double(:fei => :also_not_me, :message => 'yippee!')
      ])
      allow(subject).to receive_messages(:process => process)
      expect(subject.error.message).to eq('boo!')
    end

    it 'returns nil if no error during this expression' do
      process = double
      allow(process).to receive_messages(:errors => [
        double(:fei => :not_me, :message => 'alarming!'),
        double(:fei => :also_not_me, :message => 'yippee!')
      ])
      allow(subject).to receive_messages(:process => process)
      expect(subject.error).to be_nil
    end
  end

  describe '#cancel!' do
    it 'cancels the expression' do
      expect(Bumbleworks.dashboard).to receive(:cancel_expression).with(fei)
      subject.cancel!
    end
  end

  describe '#kill!' do
    it 'kills the expression' do
      expect(Bumbleworks.dashboard).to receive(:kill_expression).with(fei)
      subject.kill!
    end
  end

  describe '#workitem' do
    it 'returns the workitem as applied to this expression' do
      allow(fexp).to receive(:applied_workitem).and_return(:something_raw)
      expect(subject.workitem).to eq(Bumbleworks::Workitem.new(:something_raw))
    end
  end
end
