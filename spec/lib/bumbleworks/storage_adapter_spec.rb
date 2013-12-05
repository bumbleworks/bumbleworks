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

  describe '.wrap_storage_with_driver' do
    before :each do
      storage_driver = double('storage_driver')
      storage_driver.stub(:new).with(:awesome_stuff).and_return(:new_storage)
      described_class.stub(:driver => storage_driver)
    end

    it 'returns driven storage' do
      described_class.wrap_storage_with_driver(:awesome_stuff).should == :new_storage
    end
  end

  describe '.new_storage' do
    before :each do
      described_class.stub(:wrap_storage_with_driver).with(:awesome_stuff).and_return(:new_storage)
    end

    it 'returns driven storage if driver can use storage' do
      described_class.stub(:use?).with(:awesome_stuff).and_return(true)
      described_class.new_storage(:awesome_stuff).should == :new_storage
    end

    it "raises UnsupportedStorage if driver can't use storage" do
      described_class.stub(:use?).with(:awesome_stuff).and_return(false)
      expect {
        described_class.new_storage(:awesome_stuff)
      }.to raise_error(Bumbleworks::StorageAdapter::UnsupportedStorage)
    end
  end
end