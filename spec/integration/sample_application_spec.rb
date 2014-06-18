describe 'Bumbleworks Sample Application' do
  let(:app_root) {
    File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories'))
  }

  before :each do
    load File.join(app_root, 'full_initializer.rb')
  end

  describe 'initializer' do
    it 'registers participants' do
      expect(Bumbleworks.dashboard.participant_list.size).to eq(5)
      expect(Bumbleworks.dashboard.participant_list.map(&:classname)).to eq([
        'Bumbleworks::ErrorDispatcher',
        'Bumbleworks::EntityInteractor',
        'HoneyParticipant',
        'MolassesParticipant',
        'Bumbleworks::StorageParticipant'
      ])
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
      expect(Bumbleworks::Task.size).to eq(1)
    end

    it 'creates tasks for concurrent workflows' do
      Bumbleworks.launch!('make_molasses')
      Bumbleworks.dashboard.wait_for(:dave)
      expect(Bumbleworks::Task.size).to eq(2)
      expect(Bumbleworks::Task.for_role('dave').size).to eq(1)
      expect(Bumbleworks::Task.for_role('sam').size).to eq(1)
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

  describe 'dispatching a task' do
    it 'triggers after_dispatch callback' do
      Bumbleworks.launch!('make_honey')
      Bumbleworks.dashboard.wait_for(:dave)
      task = Bumbleworks::Task.for_role('dave').first
      task['i_was_dispatched'].should == 'yes_i_was'
    end
  end
end

