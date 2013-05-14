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
    it 'is a subclass responsibility' do
      expect { described_class.display_name }.to raise_error
    end
  end

  describe '.driver' do
    it 'is a subclass responsibility' do
      expect { described_class.driver }.to raise_error
    end
  end

  describe '.use?' do
    before :each do
      described_class.stub(:display_name).and_return('String')
    end

    it 'returns true if argument class name matches display name' do
      described_class.use?('a string').should be_true
      described_class.use?(:not_a_string).should be_false
    end
  end
end