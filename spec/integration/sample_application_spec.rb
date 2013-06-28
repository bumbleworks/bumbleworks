describe 'Bumbleworks Sample Application' do
  let(:app_root) {
    File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories'))
  }

  before :each do
    Bumbleworks.reset!
    load File.join(app_root, 'full_initializer.rb')
  end

  describe 'initializer' do
    it 'registers participants' do
      Bumbleworks.dashboard.participant_list.should have(3).items
      Bumbleworks.dashboard.participant_list.map(&:classname).should =~ ['HoneyParticipant', 'MolassesParticipant', 'Ruote::StorageParticipant']
    end

    it 'loads process definitions' do
      Bumbleworks.dashboard.variables['make_honey'].should == ["define",
        {"name"=>"make_honey"}, [["dave", {"task"=>"make_some_honey"}, []]]]
      Bumbleworks.dashboard.variables['garbage_collector'].should == ["define",
        {"name"=>"garbage_collector"}, [["george", {"ref"=>"garbage collector"}, []]]]

      Bumbleworks.dashboard.variables['make_molasses'].should == ["define",
        {"name"=>"make_molasses"},
        [["concurrence",
          {},
          [["dave", {"task"=>"make_some_molasses"}, []], ["sam", {"task"=>"taste_that_molasses"}, []]]]]]
    end
  end

  describe 'launching process' do
    it 'waits for first task in catchall participant' do
      Bumbleworks.launch!('make_honey')
      Bumbleworks.dashboard.wait_for(:dave)
      Bumbleworks::Task.all.should have(1).item
    end

    it 'creates tasks for concurrent workflows' do
      Bumbleworks.launch!('make_molasses')
      Bumbleworks.dashboard.wait_for(:dave)
      Bumbleworks::Task.all.should have(2).item
      Bumbleworks::Task.for_role('dave').should have(1).item
      Bumbleworks::Task.for_role('sam').should have(1).item
    end
  end

  describe 'updating a task' do
    it 'calls callbacks' do
      Bumbleworks.launch!('make_honey')
      Bumbleworks.dashboard.wait_for(:dave)
      task = Bumbleworks::Task.for_role('dave').first
      task.update('happening' => 'update')
      task['what_happened'].should == 'update'
    end
  end
end

