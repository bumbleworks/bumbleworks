require "bumbleworks/workitem_entity_storage"

describe Bumbleworks::WorkitemEntityStorage do
  let(:fake_entity_holder) {
    Class.new {
      include Bumbleworks::WorkitemEntityStorage
      attr_reader :workitem
      def initialize(workitem)
        @workitem = workitem
      end
    }
  }

  describe '#entity_storage_workitem' do
    it 'returns new Bumbleworks::Workitem instance with workitem' do
      Bumbleworks::Workitem.stub(:new).with(:a_workitem).and_return(:the_workitem)
      feh = fake_entity_holder.new(:a_workitem)
      feh.entity_storage_workitem.should == :the_workitem
    end

    it 'is memoized' do
      feh = fake_entity_holder.new(:a_workitem)
      esw = feh.entity_storage_workitem
      feh.entity_storage_workitem.should be esw
    end
  end

  [:has_entity_fields?, :has_entity?, :entity, :entity_fields, :entity_name].each do |method|
    describe "##{method}" do
      it 'delegates to entity storage workitem' do
        feh = fake_entity_holder.new(:a_workitem)
        feh.entity_storage_workitem.stub(method).with(1, 2, 3).and_return(:yay_for_bikes)
        feh.send(method, 1, 2, 3).should == :yay_for_bikes
      end
    end
  end
end