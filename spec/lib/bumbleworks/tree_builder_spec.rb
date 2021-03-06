describe Bumbleworks::TreeBuilder do
  describe '.new' do
    it 'raises error if no definition or tree' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'raises error if both definition and tree' do
      expect {
        described_class.new(:definition => :foo, :tree => :bar)
      }.to raise_error(ArgumentError)
    end

    it 'succeeds if only one of definition or tree specified' do
      expect { described_class.new(:definition => :foo) }.not_to raise_error
      expect { described_class.new(:tree => :foo) }.not_to raise_error
    end
  end

  describe '#build!' do
    it 'builds tree and sets name to given name' do
      pdef = %q(
        Bumbleworks.define_process do
          order_pants_around
        end
      )
      builder = described_class.new(:name => 'luigi', :definition => pdef)
      expect(builder.build!).to eq([
        "define", {"name" => "luigi"},
        [
          ["order_pants_around", {}, []]
        ]
      ])
    end

    it 'uses tree if given' do
      tree = ["define", {"guppies" => nil}, [["swim", {}, []]]]
      builder = described_class.new(:tree => tree)
      expect(builder.build!).to eq( 
        ["define", {"name" => "guppies"}, [["swim", {}, []]]]
      )
    end

    it 'normalizes and sets name from tree' do
      pdef = %q(
        Bumbleworks.define_process 'country_time_county_dime' do
          do_the_fig_newton
        end
      )
      builder = described_class.new(:definition => pdef)
      expect(builder.build!).to eq([
        "define", {"name" => "country_time_county_dime"},
        [
          ["do_the_fig_newton", {}, []]
        ]
      ])
    end

    it 'raises error if name conflicts with name in definition' do
      pdef = %q(
        Bumbleworks.define_process :name => 'stromboli' do
          order_pants_around
        end
      )
      builder = described_class.new(:name => 'contorti', :definition => pdef)
      expect {
        builder.build!
      }.to raise_error(described_class::InvalidTree, "Name does not match name in definition" )
    end

    it 'raises error if process is unparseable' do
      pdef = "A quiet evening with the deaf lemurs"
      builder = described_class.new(:name => 'lemur_joy', :definition => pdef)
      expect {
        builder.build!
      }.to raise_error(described_class::InvalidTree, "cannot read process definition" )
    end
  end

  describe '.from_definition' do
    it 'instantiates a TreeBuilder from a given block' do
      builder = described_class.from_definition 'just_another_poodle_day' do
        chew :on => 'dad'
        construct :solution => 'to world conflict'
      end
      builder.build!
      expect(builder.tree).to eq(
        ["define", { "name" => "just_another_poodle_day" },
          [
            ["chew", {"on" => "dad"}, []],
            ["construct", {"solution" => "to world conflict"}, []]
          ]
        ]
      )
      expect(builder.name).to eq('just_another_poodle_day')
    end
  end
end