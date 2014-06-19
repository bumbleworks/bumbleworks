shared_examples "an entity holder" do
  [:has_entity_fields?, :has_entity?, :entity, :entity_fields, :entity_name].each do |method|
    describe "##{method}" do
      it 'delegates to entity storage workitem' do
        allow(holder.entity_storage_workitem).to receive(method).with(1, 2, 3).and_return(:yay_for_bikes)
        expect(holder.send(method, 1, 2, 3)).to eq(:yay_for_bikes)
      end
    end
  end

  describe "#entity_storage_workitem" do
    it 'returns the expected workitem' do
      expect(holder.entity_storage_workitem).to eq(storage_workitem)
    end
  end
end