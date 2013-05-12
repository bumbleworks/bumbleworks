describe Bumbleworks::ProcessDefinition do
  describe '.create!' do
    it 'raises an error if file not found' do
      expect {described_class.create!('no_say')}.to raise_error(Bumbleworks::DefinitionFileNotFound)
    end

    it 'loads the process defintion from the file' do
      fixture_file = File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories', 'lib/process_definitions/make_honey.rb'), __FILE__)
      described_class.should_receive(:load).with(fixture_file)
      described_class.create!(fixture_file)
    end
  end

  describe '.define_process' do
    it 'adds a the name of process definition to Ruote' do
      process_definiton = described_class.define_process('foot-traffic') do
      end
      process_definiton.should_not be_nil
    end

    it 'adds processes the definition Ruote' do
      process_definition = described_class.define_process('foot-traffic') do
        nike 'ok'
        adidas 'nice'
      end

      process_definition.should == ["define", {"name"=>"foot-traffic"},
                                              [["nike", {"ok"=>nil}, []],
                                               ["adidas", {"nice"=>nil}, []]]]
    end
  end
end
