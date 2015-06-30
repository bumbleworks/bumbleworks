describe Bumbleworks::ProcessDefinition do
  let(:valid_definition) { %q(
    Bumbleworks.define_process 'monkeys' do
      chocolate_covered_skis :are => 'awesome'
    end
  )}

  it "can be constructed with name and definition" do
    pdef = described_class.new(:name => 'zach', :definition => 'orbo')
    expect(pdef.name).to eq('zach')
    expect(pdef.definition).to eq('orbo')
  end

  it "can be constructed with name and tree" do
    pdef = described_class.new(:name => 'zach', :tree => ["define", {"your" => "face"}])
    expect(pdef.name).to eq('zach')
    expect(pdef.tree).to eq(["define", {"your" => "face"}])
  end

  describe '#build_tree!' do
    it "converts Bumbleworks definition to Ruote tree" do
      pdef = described_class.new(:name => 'monkeys', :definition => valid_definition)
      expect(pdef.build_tree!).to eq([
        "define", {"name" => "monkeys"},
        [
          ["chocolate_covered_skis", {"are" => "awesome"}, []]
        ]
      ])
    end

    it "raises error if name in definition does not match" do
      wrong_named_def = valid_definition.gsub(/monkeys/, 'slot_cats')
      pdef = described_class.new(:name => 'monkeys', :definition => wrong_named_def)
      expect {
        pdef.build_tree!
      }.to raise_error(described_class::Invalid, /Name does not match name in definition/)
    end

    it "adds name to tree when not specified in definition" do
      unnamed_def = valid_definition.gsub(/ 'monkeys'/, '')
      pdef = described_class.new(:name => 'spit_salad', :definition => unnamed_def)
      expect(pdef.build_tree!).to eq([
        "define", {"name" => "spit_salad"},
        [
          ["chocolate_covered_skis", {"are" => "awesome"}, []]
        ]
      ])
    end
  end

  describe "#validate!" do
    it "raises error if name not specified" do
      expect {
        described_class.new.validate!
      }.to raise_error(described_class::Invalid, /Name must be specified/)
    end

    it "raises error if definition and tree not specified" do
      expect {
        described_class.new.validate!
      }.to raise_error(described_class::Invalid, /Definition or tree must be specified/)
    end

    it "raises error if definition invalid" do
      pdef = described_class.new(:name => 'yay', :definition => 'do good stuff')
      expect {
        pdef.validate!
      }.to raise_error(described_class::Invalid, /Definition is not a valid process definition/)
    end
  end

  describe "#save!" do
    it "validates" do
      pdef = described_class.new
      expect(pdef).to receive(:validate!)
      pdef.save!
    end

    it "raises validation error if invalid" do
      expect {
        described_class.new.save!
      }.to raise_error(described_class::Invalid)
    end

    it "registers the process definition with the dashboard" do
      pdef = described_class.new(:name => 'monkeys', :definition => valid_definition)
      pdef.save!
      expect(Bumbleworks.dashboard.variables['monkeys']).to eq(
        pdef.build_tree!
      )
    end

    it "overwrites existing variable with new definition" do
      Bumbleworks.dashboard.variables['monkeys'] = 'A miraculous ingredient'
      pdef = described_class.new(:name => 'monkeys', :definition => valid_definition)
      pdef.save!
      expect(Bumbleworks.dashboard.variables['monkeys']).to eq(
        pdef.build_tree!
      )
    end
  end

  describe ".find_by_name" do
    it "returns an instance with a previously registered definition" do
      Bumbleworks.dashboard.variables['foo'] = 'go to the bar'
      pdef = described_class.find_by_name('foo')
      expect(pdef.tree).to eq('go to the bar')
    end

    it "raises an error if registered definition can't be found by given name" do
      expect { described_class.find_by_name('nerf') }.to raise_error(described_class::NotFound)
    end
  end

  describe "#load_definition_from_file" do
    it "raises an error if given file can't be found" do
      pdef = described_class.new(:name => 'whatever')
      expect { pdef.load_definition_from_file('nerf') }.to raise_error(described_class::FileNotFound)
    end

    it "sets #definition to the parsed result of the file, if found" do
      pdef = described_class.new(:name => 'test_process')
      pdef.load_definition_from_file definition_path('test_process')
      expect(pdef.definition).to eq(File.read(definition_path('test_process')))
    end
  end

  describe '.create_all_from_directory!' do
    let(:definitions_path) { File.join(fixtures_path, 'definitions') }

    it 'raises error if any invalid files are encountered' do
      expect {
        described_class.create_all_from_directory!(definitions_path)
      }.to raise_error(described_class::Invalid)
    end

    it 'raises error if duplicate filenames are encountered' do
      allow(Bumbleworks::Support).to receive(:all_files).and_return({
        'Rhubarb Derailleur' => 'popular_side_dish',
        'Cantonese Phrasebook' => 'popular_side_dish',
        'Beans' => 'unpopular_side_dish'
      })
      expect {
        described_class.create_all_from_directory!(definitions_path)
      }.to raise_error(described_class::DuplicatesInDirectory)
    end

    it 'rolls back any processes defined within current transaction if error' do
      Bumbleworks.dashboard.variables['keep_me'] = 'top_secret_cat_pics'
      # stubbing here so we can explicitly set an order which will
      # ensure we're testing rollback
      allow(Bumbleworks::Support).to receive(:all_files).and_return({
        definition_path('test_process') => 'test_process',
        definition_path('a_list_of_jams') => 'a_list_of_jams'
      })
      expect {
        described_class.create_all_from_directory!(definitions_path)
      }.to raise_error(described_class::Invalid)
      expect(Bumbleworks.dashboard.variables['test_process']).to be_nil
      expect(Bumbleworks.dashboard.variables['keep_me']).to eq('top_secret_cat_pics')
    end

    it 'skips invalid files and loads all valid definitions when option specified' do
      described_class.create_all_from_directory!(definitions_path, :skip_invalid => true)
      expect(Bumbleworks.dashboard.variables['test_process']).to eq(
        ["define", { "name" => "test_process" }, [["nothing", {}, []]]]
      )
      expect(Bumbleworks.dashboard.variables['test_nested_process']).to eq(
        ["define", { "name" => "test_nested_process" }, [["nothing_nested", {}, []]]]
      )
      expect(Bumbleworks.dashboard.variables['a_list_of_jams']).to be_nil
    end
  end

  describe '.create!' do
    it 'builds and saves a new instance' do
      pdef = described_class.create!(:name => 'monkeys', :definition => valid_definition)
      expect(Bumbleworks.dashboard.variables['monkeys']).to eq(
        pdef.build_tree!
      )
    end
  end

  describe '.define' do
    it 'creates a process definition from a given block' do
      definition = described_class.define 'nammikins' do
        treefles
      end
      expect(Bumbleworks.dashboard.variables['nammikins']).to eq(
        ["define", {"name" => "nammikins"}, [["treefles", {}, []]]]
      )
    end
  end
end
