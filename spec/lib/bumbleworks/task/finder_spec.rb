describe Bumbleworks::Task::Finder do
  before :each do
    Bumbleworks.reset!
    Bumbleworks.storage = {}
    Bumbleworks::Ruote.register_participants
    Bumbleworks.start_worker!
    Bumbleworks.define_process 'dog-lifecycle' do
      concurrence do
        dog :task => 'eat'
        dog :task => 'bark'
        dog :task => 'pet_dog'
        cat :task => 'skip_and_jump'
      end
    end
  end

  describe '#all' do
    it 'uses Bumbleworks::Task class by default for task generation' do
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      tasks = Bumbleworks::Task::Finder.new.all
      tasks.should be_all { |t| t.class == Bumbleworks::Task }
    end

    it 'uses provided class for task generation' do
      class MyOwnTask < Bumbleworks::Task; end
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      tasks = Bumbleworks::Task::Finder.new([], MyOwnTask).all
      tasks.should be_all { |t| t.class == MyOwnTask }
      Object.send(:remove_const, :MyOwnTask)
    end
  end

  describe '#available' do
    it 'adds both unclaimed and completable filters' do
      query = Bumbleworks::Task::Finder.new
      query.should_receive(:unclaimed).and_return(query)
      query.should_receive(:completable).and_return(query)
      query.available
    end
  end
end
