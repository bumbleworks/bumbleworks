shared_examples "an entity holder" do
  [:has_entity_fields?, :has_entity?, :entity, :entity_fields, :entity_name].each do |method|
    describe "##{method}" do
      it 'delegates to entity storage workitem' do
        holder.entity_storage_workitem.stub(method).with(1, 2, 3).and_return(:yay_for_bikes)
        holder.send(method, 1, 2, 3).should == :yay_for_bikes
      end
    end
  end

  describe "#entity_storage_workitem" do
    it 'returns the expected workitem' do
      holder.entity_storage_workitem.should == storage_workitem
    end
  end
end