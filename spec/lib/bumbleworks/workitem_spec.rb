require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))

describe Bumbleworks::Workitem do
  let(:ruote_workitem) { Ruote::Workitem.new('fields' => {'entity_id' => '123', 'entity_type' => 'RainbowLoom'} ) }
  let(:workitem) { Bumbleworks::Workitem.new(ruote_workitem)}

  describe '#==' do
    it 'returns true if other object has same raw workitem' do
      bw1 = described_class.new('in_da_sky')
      bw2 = described_class.new('in_da_sky')
      bw1.should == bw2
    end
  end

  describe '#has_entity_fields?' do
    it 'returns true if workitem fields include entity fields' do
      workitem.should have_entity_fields
    end

    it 'returns true if workitem fields include symbolized version of entity fields' do
      ruote_workitem.fields = { :entity_id => '123', :entity_type => 'RainbowLoom' }
      workitem.should have_entity_fields
    end

    it 'returns false if workitem fields do not include entity fields' do
      ruote_workitem.fields = {}
      workitem.should_not have_entity_fields
    end
  end

  describe '#has_entity?' do
    it 'returns true if entity is not nil' do
      workitem.stub(:entity).and_return(:a_real_boy_not_a_puppet)
      workitem.has_entity?.should be_true
    end

    it 'returns false if EntityNotFound' do
      workitem.stub(:entity).and_raise(Bumbleworks::EntityNotFound)
      workitem.has_entity?.should be_false
    end
  end

  describe '#entity' do
    it 'attempts to instantiate business entity from _id and _type fields' do
      workitem.entity.identifier.should == '123'
    end

    it 'works with symbolized _id and _type fields' do
      ruote_workitem.fields = { :entity_id => '125', :entity_type => 'RainbowLoom' }
      workitem.entity.identifier.should == '125'
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
      workitem.entity.identifier.should == 'nerfus'
    end

    it 'reloads instance when called with reload option' do
      workitem.entity.identifier = 'pickles'
      workitem.entity(:reload => true).identifier.should == '123'
    end
  end

  describe "#entity_fields" do
    it 'returns empty hash if no entity' do
      ruote_workitem.fields = {}
      workitem.entity_fields.should == {}
    end

    it 'returns class name and identifier by default' do
      workitem.entity_fields.should == { :type => 'RainbowLoom', :identifier => '123' }
    end

    it 'humanizes class name when requested' do
      workitem.entity_fields(:humanize => true).should == { :type => 'Rainbow loom', :identifier => '123' }
    end

    it 'titleizes class name when requested' do
      workitem.entity_fields(:titleize => true).should == { :type => 'Rainbow Loom', :identifier => '123' }
    end
  end

  describe "#entity_name" do
    it 'returns entity fields in displayable string' do
      workitem.entity_name.should == 'Rainbow Loom 123'
    end
  end
end
