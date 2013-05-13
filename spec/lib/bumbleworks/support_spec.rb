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

    it "for given directory, yields given block with path and name params" do
      assembled_hash = {}
      described_class.all_files(test_directory) do |path, name|
        assembled_hash[name] = path
      end

      assembled_hash['test_process'].should ==
        File.join(fixtures_path, 'definitions', 'test_process.rb').to_s
      assembled_hash['test_nested_process'].should ==
        File.join(fixtures_path, 'definitions', 'nested_folder', 'test_nested_process.rb').to_s
    end

    it "camelizes names if :camelize option is true " do
      path = File.join(fixtures_path, 'definitions')
      assembled_hash = {}
      described_class.all_files(test_directory, :camelize => true) do |path, name|
        assembled_hash[name] = path
      end

      assembled_hash['TestProcess'].should ==
        File.join(fixtures_path, 'definitions', 'test_process.rb').to_s
      assembled_hash['TestNestedProcess'].should ==
        File.join(fixtures_path, 'definitions', 'nested_folder', 'test_nested_process.rb').to_s
    end
  end
end