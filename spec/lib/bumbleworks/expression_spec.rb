describe Bumbleworks::Expression do
  let(:fei) { double({ :expid => '1_2_3', :wfid => 'snooks' }) }
  let(:fexp) { double('FlowExpression', :fei => fei, :tree => :a_tree) }
  subject { described_class.new(fexp) }

  describe '.from_fei' do
    it 'returns instance generated from FlowExpressionId' do
      allow(::Ruote::Exp::FlowExpression).to receive(:fetch).
        with(Bumbleworks.dashboard.context, fei).and_return(fexp)
      expect(described_class.from_fei(fei)).to eq(described_class.new(fexp))
    end
  end

  describe '#==' do
    it 'returns true if other object has same flow expression id' do
      exp1 = described_class.new(fexp)
      exp2 = described_class.new(double('FlowExpression', :fei => fei))
      expect(exp1).to eq(exp2)
    end

    it 'returns false if other object has different flow expression id' do
      exp1 = described_class.new(fexp)
      exp2 = described_class.new(double('FlowExpression', :fei => double(:expid => '4')))
      expect(exp1).not_to eq(exp2)
    end

    it 'returns false if other object has is not an expression' do
      exp1 = described_class.new(fexp)
      exp2 = double('not an expression')
      expect(exp1).not_to eq(exp2)
    end
  end

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
