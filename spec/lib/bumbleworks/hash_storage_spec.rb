describe Bumbleworks::HashStorage do
  describe '.allow_history_storage?' do
    it 'returns false' do
      expect(described_class.allow_history_storage?).to be_falsy
    end

    it 'is a Bumbleworks::StorageAdapter' do
      expect(described_class.superclass).to eq(Bumbleworks::StorageAdapter)
    end
  end
end