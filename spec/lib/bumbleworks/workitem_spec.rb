require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))

describe Bumbleworks::Workitem do
  let(:ruote_workitem) { Ruote::Workitem.new('fields' => {'entity_id' => '123', 'entity_type' => 'RainbowLoom'} ) }
  subject { described_class.new(ruote_workitem) }

  it_behaves_like "comparable" do
    subject { described_class.new(ruote_workitem) }
    let(:other) { described_class.new(ruote_workitem) }
  end

  describe '#has_entity_fields?' do
    it 'returns true if workitem fields include entity fields' do
      expect(subject).to have_entity_fields
    end

    it 'returns true if workitem fields include symbolized version of entity fields' do
      ruote_workitem.fields = { :entity_id => '123', :entity_type => 'RainbowLoom' }
      expect(subject).to have_entity_fields
    end

    it 'returns false if workitem fields do not include entity fields' do
      ruote_workitem.fields = {}
      expect(subject).not_to have_entity_fields
    end
  end

  describe '#has_entity?' do
    it 'returns true if entity is not nil' do
      allow(subject).to receive(:entity).and_return(:a_real_boy_not_a_puppet)
      expect(subject.has_entity?).to be_truthy
    end

    it 'returns false if EntityNotFound' do
      allow(subject).to receive(:entity).and_raise(Bumbleworks::EntityNotFound)
      expect(subject.has_entity?).to be_falsy
    end
  end

  describe '#entity' do
    it 'attempts to instantiate business entity from _id and _type fields' do
      expect(subject.entity.identifier).to eq('123')
    end

    it 'works with symbolized _id and _type fields' do
      ruote_workitem.fields = { :entity_id => '125', :entity_type => 'RainbowLoom' }
      expect(subject.entity.identifier).to eq('125')
    end

    it 'throw exception if entity fields not present' do
      ruote_workitem.fields = {}
      expect {
        subject.entity
      }.to raise_error Bumbleworks::EntityNotFound
    end

    it 'throw exception if entity returns nil' do
      ruote_workitem.fields['entity_id'] = nil
      expect {
        subject.entity
      }.to raise_error Bumbleworks::EntityNotFound, '{:entity_id=>nil, :entity_type=>"RainbowLoom"}'
    end

    it 'returns same instance when called twice' do
      subject.entity.identifier = 'nerfus'
      expect(subject.entity.identifier).to eq('nerfus')
    end

    it 'reloads instance when called with reload option' do
      subject.entity.identifier = 'pickles'
      expect(subject.entity(:reload => true).identifier).to eq('123')
    end
  end

  describe '#tokenized_entity_type' do
    it 'returns tokenized entity type' do
      expect(subject.tokenized_entity_type).to eq('rainbow_loom')
    end

    it 'returns nil if no entity type' do
      allow(subject).to receive(:entity_type).and_return(nil)
      expect(subject.tokenized_entity_type).to be_nil
    end
  end

  describe "#entity_fields" do
    it 'returns empty hash if no entity' do
      ruote_workitem.fields = {}
      expect(subject.entity_fields).to eq({})
    end

    it 'returns class name and identifier by default' do
      expect(subject.entity_fields).to eq({ :type => 'RainbowLoom', :identifier => '123' })
    end

    it 'humanizes class name when requested' do
      expect(subject.entity_fields(:humanize => true)).to eq({ :type => 'Rainbow loom', :identifier => '123' })
    end

    it 'titleizes class name when requested' do
      expect(subject.entity_fields(:titleize => true)).to eq({ :type => 'Rainbow Loom', :identifier => '123' })
    end
  end

  describe "#entity_name" do
    it 'returns entity fields in displayable string' do
      expect(subject.entity_name).to eq('Rainbow Loom 123')
    end
  end
end
