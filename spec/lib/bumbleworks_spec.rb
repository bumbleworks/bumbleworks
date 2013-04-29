require 'spec_helper'

describe Bumbleworks do
  describe ".configure" do
    it 'yields the current configuration' do
      described_class.configure do |c|
        expect(c).to equal(described_class.configuration)
      end
    end
  end

  describe '.reset' do
    it 'resets memoized variables' do
      configuration = described_class.configuration
      described_class.reset!
      described_class.configuration.should_not equal(configuration)
    end
  end

  describe '.configuration' do
    before :each do
      described_class.reset!
    end

    let!(:configuration) do
      double.tap do |configuration|
        Bumbleworks::Configuration.should_receive(:new).and_return(configuration)
      end
    end

    it 'creates an instance of Bumbleworks::Configuration' do
      described_class.configuration.should == configuration
    end

    it 'returns the same instance when called multiple times' do
      described_class.configuration.should == configuration
      described_class.configuration.should == configuration
    end
  end

end
