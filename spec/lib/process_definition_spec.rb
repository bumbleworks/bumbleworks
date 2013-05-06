describe Bumbleworks::ProcessDefinition do
  describe '.create!' do
    it 'raises an error if file not found' do
      expect {described_class.create!('no_say')}.to raise_error(Bumbleworks::DefinitionFileNotFound)
    end

    it 'loads the process defintion from the file' do
      fixture_file = File.expand_path('../../fixture_app/lib/process_definitions/make_honey.rb', __FILE__)
      described_class.should_receive(:load).with(fixture_file)
      described_class.create!(fixture_file)
    end
  end

  describe '.define_process' do
    before :each do
      @variables = {}
      engine = double(:variables => @variables)
      Bumbleworks.stub(:engine => engine)
    end

    it 'adds a the name of process definition to Ruote' do
      described_class.define_process('foot-traffic') do
      end
      @variables['foot-traffic'].should_not be_nil
    end

    it 'adds processes the definition Ruote' do
      described_class.define_process('foot-traffic') do
        nike 'ok'
        adidas 'nice'
      end

      @variables['foot-traffic'].should == ["define", {"name"=>"foot-traffic"},
                                              [["nike", {"ok"=>nil}, []],
                                               ["adidas", {"nice"=>nil}, []]]]
    end

    it 'should raise an error when duplicate process names are detected' do
      described_class.define_process('foot-traffic') do
      end

      expect do
        described_class.define_process('foot-traffic') do
        end
      end.to raise_error
    end
  end
end
