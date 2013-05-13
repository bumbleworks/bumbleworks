describe Bumbleworks::TreeBuilder do
  describe '#build!' do
    it 'builds tree and sets name to given name' do
      pdef = %q(
        Bumbleworks.define_process do
          order_pants_around
        end
      )
      builder = described_class.new(:name => 'luigi', :definition => pdef)
      builder.build!.should == [
        "define", {"name" => "luigi"},
        [
          ["order_pants_around", {}, []]
        ]
      ]
    end

    it 'uses tree if given' do
      tree = ["define", {"guppies" => nil}, [["swim", {}, []]]]
      builder = described_class.new(:tree => tree)
      builder.build!.should == 
        ["define", {"name" => "guppies"}, [["swim", {}, []]]]
    end

    it 'normalizes and sets name from tree' do
      pdef = %q(
        Bumbleworks.define_process 'country_time_county_dime' do
          do_the_fig_newton
        end
      )
      builder = described_class.new(:definition => pdef)
      builder.build!.should == [
        "define", {"name" => "country_time_county_dime"},
        [
          ["do_the_fig_newton", {}, []]
        ]
      ]
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
      builder.tree.should ==
        ["define", { "name" => "just_another_poodle_day" },
          [
            ["chew", {"on" => "dad"}, []],
            ["construct", {"solution" => "to world conflict"}, []]
          ]
        ]
      builder.name.should == 'just_another_poodle_day'
    end
  end
end