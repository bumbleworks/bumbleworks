require "bumbleworks/workitem_entity_storage"

describe Bumbleworks::WorkitemEntityStorage do
  class FakeEntityHolder
    include Bumbleworks::WorkitemEntityStorage
    def initialize(fields = {})
      @fields = fields
    end

    def workitem
      OpenStruct.new(:fields => @fields)
    end
  end

  describe '#has_entity_fields?' do
    it 'returns true if workitem fields include entity fields' do
      feh = FakeEntityHolder.new('entity_id' => '1', 'entity_type' => 'SomeEntity')
      feh.should have_entity_fields
    end

    it 'returns false if workitem fields do not include entity fields' do
      feh = FakeEntityHolder.new
      feh.should_not have_entity_fields
    end
  end

  describe '#has_entity?' do
    it 'returns true if entity is not nil' do
      feh = FakeEntityHolder.new
      feh.stub(:entity).and_return(:a_real_boy_not_a_puppet)
      feh.has_entity?.should be_true
    end

    it 'returns false if EntityNotFound' do
      feh = FakeEntityHolder.new
      feh.stub(:entity).and_raise(Bumbleworks::WorkitemEntityStorage::EntityNotFound)
      feh.has_entity?.should be_false
    end
  end

  describe '#entity' do
    before :all do
      class LovelyEntity
        attr_accessor :identifier
        def initialize(identifier)
          @identifier = identifier
        end

        def self.first_by_identifier(identifier)
          return nil unless identifier
          new(identifier)
        end
      end
    end

    after :all do
      Object.send(:remove_const, :LovelyEntity)
    end

    let(:entitied_workflow_item) {
      Ruote::Workitem.new('fields' => {
        'entity_id' => '15',
        'entity_type' => 'LovelyEntity',
        'params' => {'task' => 'go_to_work'}
      })
    }

    it 'attempts to instantiate business entity from _id and _type fields' do
      feh = FakeEntityHolder.new('entity_id' => '15', 'entity_type' => 'LovelyEntity')
      feh.entity.identifier.should == '15'
    end

    it 'throw exception if entity fields not present' do
      feh = FakeEntityHolder.new
      expect {
        feh.entity
      }.to raise_error Bumbleworks::WorkitemEntityStorage::EntityNotFound
    end

    it 'throw exception if entity returns nil' do
      feh = FakeEntityHolder.new('entity_id' => nil, 'entity_type' => 'LovelyEntity')
      expect {
        feh.entity
      }.to raise_error Bumbleworks::WorkitemEntityStorage::EntityNotFound
    end

    it 'returns same instance when called twice' do
      feh = FakeEntityHolder.new('entity_id' => '15', 'entity_type' => 'LovelyEntity')
      feh.entity.identifier = 'pickles'
      feh.entity.identifier.should == 'pickles'
    end

    it 'reloads instance when called with reload option' do
      feh = FakeEntityHolder.new('entity_id' => '15', 'entity_type' => 'LovelyEntity')
      feh.entity.identifier = 'pickles'
      feh.entity(:reload => true).identifier.should == '15'
    end
  end
end