describe Bumbleworks::ProcessDefinition do
  describe '.create!' do
    it 'returns an instance of ProcessDefinition' do
      described_class.any_instance.stub(:load_definition_from_file)
      described_class.any_instance.stub(:save!)
      described_class.create!('somefile').should be_an_instance_of(described_class)
    end
  end

  describe '#load_definition_from_file' do
    it 'raises an error if file not found' do
      pdef = described_class.new(nil)
      expect {pdef.load_definition_from_file}.to raise_error(Bumbleworks::DefinitionFileNotFound)
    end

    it 'loads the process defintion from the file' do
      fixture_file = File.expand_path('../../fixture_app/lib/process_definitions/make_honey.rb', __FILE__)
      pdef = described_class.new(fixture_file)
      pdef.load_definition_from_file.should == ["define", {"make_honey"=>nil}, [["dave", {"ref" => "honey maker"}, []]]]
    end
  end
end
