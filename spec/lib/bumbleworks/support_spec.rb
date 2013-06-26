describe Bumbleworks::Support do
  describe '.camelize' do
    it 'turns underscored string into camelcase' do
      described_class.camelize('foo_bar_One_two_3').should == 'FooBarOneTwo3'
    end

    it 'deals with nested classes' do
      described_class.camelize('foo_bar/bar_foo').should == 'FooBar::BarFoo'
    end
  end

  describe ".all_files" do
    let(:test_directory) { File.join(fixtures_path, 'definitions').to_s }

    it "for given directory, creates hash of basename => path pairs" do
      assembled_hash = described_class.all_files(test_directory)

      assembled_hash[File.join(fixtures_path, 'definitions', 'test_process.rb').to_s].should ==
        'test_process'
      assembled_hash[File.join(fixtures_path, 'definitions', 'nested_folder', 'test_nested_process.rb').to_s].should ==
        'test_nested_process'
    end

    it "camelizes names if :camelize option is true " do
      path = File.join(fixtures_path, 'definitions')
      assembled_hash = described_class.all_files(test_directory, :camelize => true)

      assembled_hash[File.join(fixtures_path, 'definitions', 'test_process.rb').to_s].should ==
        'TestProcess'
      assembled_hash[File.join(fixtures_path, 'definitions', 'nested_folder', 'test_nested_process.rb').to_s].should ==
        'TestNestedProcess'
    end
  end

  describe '.constantize' do
    before :each do
      class Whatever
        Smoothies = 'tasty'
      end
      class Boojus
      end
    end

    after :each do
      Object.send(:remove_const, :Whatever)
    end

    it 'returns value of constant with given name' do
      described_class.constantize('Whatever')::Smoothies.should == 'tasty'
    end

    it 'works with nested constants' do
      described_class.constantize('Whatever::Smoothies').should == 'tasty'
    end

    it 'does not check inheritance tree' do
      expect {
        described_class.constantize('Whatever::Boojus')
      }.to raise_error(NameError)
    end
  end
end