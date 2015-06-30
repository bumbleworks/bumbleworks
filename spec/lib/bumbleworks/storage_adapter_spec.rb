describe Bumbleworks::StorageAdapter do
  describe '.auto_register?' do
    it 'returns true if auto_register is true' do
      described_class.auto_register = true
      expect(described_class.auto_register?).to be_truthy
    end

    it 'returns false if auto_register is not true' do
      described_class.auto_register = :ghosts
      expect(described_class.auto_register?).to be_falsy
    end

    it 'is true by default' do
      described_class.auto_register = nil
      expect(described_class.auto_register?).to be_truthy
    end
  end

  describe '.display_name' do
    it 'returns storage class name as a string' do
      allow(described_class).to receive(:storage_class).and_return(String)
      expect(described_class.display_name).to eq('String')
    end
  end

  describe '.storage_class' do
    it 'is a subclass responsibility' do
      expect { described_class.storage_class }.to raise_error(StandardError, "Subclass responsibility")
    end
  end

  describe '.driver' do
    it 'is a subclass responsibility' do
      expect { described_class.driver }.to raise_error(StandardError, "Subclass responsibility")
    end
  end

  describe '.allow_history_storage?' do
    it 'defaults to true' do
      expect(described_class.allow_history_storage?).to be_truthy
    end
  end

  describe '.use?' do
    before :each do
      allow(described_class).to receive(:storage_class).and_return(String)
    end

    it 'returns true if argument class is_a storage class' do
      expect(described_class.use?('a string')).to be_truthy
      expect(described_class.use?(:not_a_string)).to be_falsy
    end
  end

  describe '.wrap_storage_with_driver' do
    before :each do
      storage_driver = double('storage_driver')
      allow(storage_driver).to receive(:new).with(:awesome_stuff).and_return(:new_storage)
      allow(described_class).to receive_messages(:driver => storage_driver)
    end

    it 'ignores options, and returns driven storage' do
      expect(described_class.wrap_storage_with_driver(:awesome_stuff, { :a => :b })).to eq(:new_storage)
    end
  end

  describe '.new_storage' do
    before :each do
      allow(described_class).to receive(:wrap_storage_with_driver).with(:awesome_stuff, { :a => :b }).and_return(:new_storage)
    end

    it 'returns driven storage if driver can use storage' do
      allow(described_class).to receive(:use?).with(:awesome_stuff).and_return(true)
      expect(described_class.new_storage(:awesome_stuff, { :a => :b })).to eq(:new_storage)
    end

    it "raises UnsupportedStorage if driver can't use storage" do
      allow(described_class).to receive(:use?).with(:awesome_stuff).and_return(false)
      expect {
        described_class.new_storage(:awesome_stuff, { :a => :b })
      }.to raise_error(Bumbleworks::StorageAdapter::UnsupportedStorage)
    end
  end
end