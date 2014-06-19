describe Bumbleworks::EntityInteractor do
  let(:entity) { double('entity', :cheek_depth => 'crazy deep') }
  let(:workitem) { Ruote::Workitem.new('fields' => { 'params' => { 'method' => 'cheek_depth' }}) }
  subject { part = described_class.new; allow(part).to receive_messages(:entity => entity, :reply => nil); part }

  describe '#on_workitem' do
    it 'calls method then replies' do
      expect(subject).to receive(:call_method).ordered
      expect(subject).to receive(:reply).ordered
      subject._on_workitem(workitem)
    end

    it 'saves the requested attribute to a workitem field' do
      workitem.fields['params']['and_save_as'] = 'entity_cheek_depth'
      subject._on_workitem(workitem)
      expect(workitem.fields['entity_cheek_depth']).to eq('crazy deep')
    end

    it 'overwrites an existing workitem field value' do
      workitem.fields['entity_cheek_depth'] = '14'
      workitem.fields['params']['and_save_as'] = 'entity_cheek_depth'
      subject._on_workitem(workitem)
      expect(workitem.fields['entity_cheek_depth']).to eq('crazy deep')
    end

    it 'calls the method even if no save_as to store the result' do
      expect(subject.entity).to receive(:cheek_depth)
      subject._on_workitem(workitem)
      expect(workitem.fields['entity_cheek_depth']).to be_nil
    end

    it 'passes arguments to method' do
      workitem.fields['params']['arguments'] = [1, 3, ['apple', 'fish']]
      workitem.fields['params']['and_save_as'] = 'entity_cheek_depth'
      expect(subject.entity).to receive(:cheek_depth).with(1, 3, ['apple', 'fish']).and_return('what')
      subject._on_workitem(workitem)
      expect(workitem.fields['entity_cheek_depth']).to eq('what')
    end

    it 'can accept "with" for arguments' do
      workitem.fields['params']['with'] = { :regular => 'joes' }
      expect(subject.entity).to receive(:cheek_depth).with({ :regular => 'joes' })
      subject._on_workitem(workitem)
    end

    it 'can use "for" param for method' do
      workitem.fields['params'] = { 'for' => 'grass_seed', 'and_save_as' => 'how_tasty' }
      expect(entity).to receive(:grass_seed).and_return('tasty-o')
      subject._on_workitem(workitem)
      expect(workitem.fields['how_tasty']).to eq('tasty-o')
    end

    it 'can use "to" param for method' do
      workitem.fields['params'] = { 'to' => 'chew_things' }
      expect(entity).to receive(:chew_things).and_return(nil)
      subject._on_workitem(workitem)
      expect(workitem.fields['who_cares']).to be_nil
    end

    it 'defaults to "method" when multiple options exist' do
      workitem.fields['params'] = { 'method' => 'really_do_this', 'to' => 'not_this', 'for' => 'definitely_not_this' }
      expect(entity).to receive(:really_do_this)
      subject._on_workitem(workitem)
    end

    it 'defaults to "to" when both "to" and "for"' do
      workitem.fields['params'] = { 'to' => 'please_call_me', 'for' => 'call_me_maybe' }
      expect(entity).to receive(:please_call_me)
      subject._on_workitem(workitem)
    end
  end

  describe '#call_method' do
    it 'calls the requested method on the entity' do
      expect(subject.call_method('cheek_depth')).to eq('crazy deep')
    end

    it 'saves the result if given a target' do
      subject.workitem = workitem
      subject.call_method('cheek_depth', :save_as => 'entity_cheek_depth')
      expect(workitem.fields['entity_cheek_depth']).to eq('crazy deep')
    end

    it 'raises an exception if no method on entity' do
      allow(subject).to receive(:entity).and_return('just an unassuming little string!')
      expect {
        subject.call_method('eat_television')
      }.to raise_error(NoMethodError)
    end
  end
end
