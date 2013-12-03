describe Bumbleworks::HashStorage do
  describe '.allow_history_storage?' do
    it 'returns false' do
      described_class.allow_history_storage?.should be_false
    end

    it 'is a Bumbleworks::StorageAdapter' do
      described_class.superclass.should == Bumbleworks::StorageAdapter
    end
  end
end