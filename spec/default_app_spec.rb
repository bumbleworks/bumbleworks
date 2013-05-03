require 'spec_helper'
require File.expand_path('../fixture_app/config/default_app', __FILE__)

describe SampleApp do
  describe "Bumbleworks.configure: use default folders" do
    let(:app_root) {File.expand_path('../fixture_app', __FILE__)}

    before :each do
      described_class.new
    end

    it 'sets Bumbleworks configuration for application root' do
      Bumbleworks.root.should == app_root
    end

    it 'discovers default Root/lib/process_definitions folder' do
      Bumbleworks.definitions_directory.should == File.join(app_root, 'lib/process_definitions')
    end

    it 'discovers default Root/app/participants directory folder' do
      Bumbleworks.participants_directory.should == File.join(app_root, 'app', 'participants' )
    end

    it 'discovers default Root/participants directory folder' do
      Bumbleworks.root = File.join(app_root, 'app')
      Bumbleworks.participants_directory.should == File.join(app_root, 'app', 'participants' )
    end

    it 'loads participants and adds the catchall at the end if not defined' do
      Bumbleworks.root = File.join(app_root, 'app')
      Bumbleworks.engine.participant_list.should have(3).items
      Bumbleworks.engine.participant_list.map(&:classname).should =~ ['HoneyParticipant', 'MolassesParticipant', 'Ruote::StorageParticipant']
    end

    it 'loads participants and and does not add catchall' do
      described_class.any_instance.stub(:register_participants) do
        Bumbleworks.register_participants do
          bees_honey 'BeesHoney'
          maple_syrup 'MapleSyrup'
          catchall 'NewCatchall'
        end
      end

      described_class.new
      Bumbleworks.root = File.join(app_root, 'app')
      Bumbleworks.engine.participant_list.should have(3).items
      Bumbleworks.engine.participant_list.map(&:classname).should =~ ['BeesHoney', 'MapleSyrup', 'NewCatchall']
    end

    it 'loads process definitions' do
      Bumbleworks.root = File.join(app_root, 'app')
      Bumbleworks.engine.variables['make_honey'].should == ["define", {"name"=>"make_honey"}, [["dave", {"ref"=>"honey maker"}, []]]]
      Bumbleworks.engine.variables['garbage_collector'].should == ["define", {"name"=>"garbage_collector"}, [["george", {"ref"=>"garbage collector"}, []]]]

      Bumbleworks.engine.variables['make_molasses'].should == ["define", {"name"=>"make_molasses", "ref"=>"good stuff"}, [["first", {"cook it"=>nil}, []], ["second", {"eat it"=>nil}, []]]]
    end
  end
end

