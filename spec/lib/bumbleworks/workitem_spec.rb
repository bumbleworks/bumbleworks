require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))

describe Bumbleworks::Workitem do
  let(:ruote_workitem) { Ruote::Workitem.new('fields' => {'entity_id' => '123', 'entity_type' => 'RainbowLoom'} ) }
  let(:workitem) { Bumbleworks::Workitem.new(ruote_workitem)}

  describe '#==' do
    it 'returns true if other object has same raw workitem' do
      bw1 = described_class.new('in_da_sky')
      bw2 = described_class.new('in_da_sky')
      expect(bw1).to eq(bw2)
    end
  end

  describe '#has_entity_fields?' do
    it 'returns true if workitem fields include entity fields' do
      expect(workitem).to have_entity_fields
    end

    it 'returns true if workitem fields include symbolized version of entity fields' do
      ruote_workitem.fields = { :entity_id => '123', :entity_type => 'RainbowLoom' }
      expect(workitem).to have_entity_fields
    end

    it 'returns false if workitem fields do not include entity fields' do
      ruote_workitem.fields = {}
      expect(workitem).not_to have_entity_fields
    end
  end

  describe '#has_entity?' do
    it 'returns true if entity is not nil' do
      allow(workitem).to receive(:entity).and_return(:a_real_boy_not_a_puppet)
      expect(workitem.has_entity?).to be_truthy
    end

    it 'returns false if EntityNotFound' do
      allow(workitem).to receive(:entity).and_raise(Bumbleworks::EntityNotFound)
      expect(workitem.has_entity?).to be_falsy
    end
  end

  describe '#entity' do
    it 'attempts to instantiate business entity from _id and _type fields' do
      expect(workitem.entity.identifier).to eq('123')
    end

    it 'works with symbolized _id and _type fields' do
      ruote_workitem.fields = { :entity_id => '125', :entity_type => 'RainbowLoom' }
      expect(workitem.entity.identifier).to eq('125')
    end

    it 'throw exception if entity fields not present' do
      ruote_workitem.fields = {}
      expect {
        workitem.entity
      }.to raise_error Bumbleworks::EntityNotFound
    end

    it 'throw exception if entity returns nil' do
      ruote_workitem.fields['entity_id'] = nil
      expect {
        workitem.entity
      }.to raise_error Bumbleworks::EntityNotFound, '{:entity_id=>nil, :entity_type=>"RainbowLoom"}'
    end

    it 'returns same instance when called twice' do
      workitem.entity.identifier = 'nerfus'
      expect(workitem.entity.identifier).to eq('nerfus')
    end

    it 'reloads instance when called with reload option' do
      workitem.entity.identifier = 'pickles'
      expect(workitem.entity(:reload => true).identifier).to eq('123')
    end
  end

  describe '#tokenized_entity_type' do
    it 'returns tokenized entity type' do
      expect(workitem.tokenized_entity_type).to eq('rainbow_loom')
    end

    it 'returns nil if no entity type' do
      allow(workitem).to receive(:entity_type).and_return(nil)
      expect(workitem.tokenized_entity_type).to be_nil
    end
  end

  describe "#entity_fields" do
    it 'returns empty hash if no entity' do
      ruote_workitem.fields = {}
      expect(workitem.entity_fields).to eq({})
    end

    it 'returns class name and identifier by default' do
      expect(workitem.entity_fields).to eq({ :type => 'RainbowLoom', :identifier => '123' })
    end

    it 'humanizes class name when requested' do
      expect(workitem.entity_fields(:humanize => true)).to eq({ :type => 'Rainbow loom', :identifier => '123' })
    end

    it 'titleizes class name when requested' do
      expect(workitem.entity_fields(:titleize => true)).to eq({ :type => 'Rainbow Loom', :identifier => '123' })
    end
  end

  describe "#entity_name" do
    it 'returns entity fields in displayable string' do
      expect(workitem.entity_name).to eq('Rainbow Loom 123')
    end
  end
end
