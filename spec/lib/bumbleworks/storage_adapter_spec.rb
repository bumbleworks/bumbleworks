describe Bumbleworks::StorageAdapter do
  describe '.auto_register?' do
    it 'returns true if auto_register is true' do
      described_class.auto_register = true
      described_class.auto_register?.should be_true
    end

    it 'returns false if auto_register is not true' do
      described_class.auto_register = :ghosts
      described_class.auto_register?.should be_false
    end

    it 'is true by default' do
      described_class.auto_register = nil
      described_class.auto_register?.should be_true
    end
  end

  describe '.display_name' do
    it 'returns storage class name as a string' do
      described_class.stub(:storage_class).and_return(String)
      described_class.display_name.should == 'String'
    end
  end

  describe '.storage_class' do
    it 'is a subclass responsibility' do
      expect { described_class.storage_class }.to raise_error
    end
  end

  describe '.driver' do
    it 'is a subclass responsibility' do
      expect { described_class.driver }.to raise_error
    end
  end

  describe '.allow_history_storage?' do
    it 'defaults to true' do
      described_class.allow_history_storage?.should be_true
    end
  end

  describe '.use?' do
    before :each do
      described_class.stub(:storage_class).and_return(String)
    end

    it 'returns true if argument class is_a storage class' do
      described_class.use?('a string').should be_true
      described_class.use?(:not_a_string).should be_false
    end
  end
end