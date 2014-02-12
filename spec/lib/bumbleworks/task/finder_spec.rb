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

  describe '#add_query' do
    it 'adds given block as new raw workitem query' do
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      finder = subject.add_query { |wi|
        wi['fields']['params']['task'] != 'pet_dog'
      }
      finder.map(&:nickname).should =~ [
        'eat',
        'bark',
        'skip_and_jump'
      ]
    end
  end

  describe '#add_filter' do
    it 'adds given block as new task filter' do
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      finder = subject.add_filter { |task|
        task.nickname != 'pet_dog'
      }
      finder.map(&:nickname).should =~ [
        'eat',
        'bark',
        'skip_and_jump'
      ]
    end
  end

  describe '#all' do
    it 'uses Bumbleworks::Task class by default for task generation' do
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      tasks = subject.all
      tasks.should be_all { |t| t.class == Bumbleworks::Task }
    end

    it 'uses provided class for task generation' do
      class MyOwnTask < Bumbleworks::Task; end
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      tasks = described_class.new([], MyOwnTask).all
      tasks.should be_all { |t| t.class == MyOwnTask }
      Object.send(:remove_const, :MyOwnTask)
    end
  end

  describe '#available' do
    it 'adds both unclaimed and completable filters' do
      subject.should_receive(:unclaimed).and_return(subject)
      subject.should_receive(:completable).and_return(subject)
      subject.available
    end
  end

  describe '#where' do
    it 'compiles a finder' do
      subject.should_receive(:available).and_return(subject)
      subject.should_receive(:by_nickname).with(:nicholas).and_return(subject)
      subject.should_receive(:for_roles).with([:dinner, :barca]).and_return(subject)
      subject.should_receive(:unclaimed).and_return(subject)
      subject.should_receive(:claimed).and_return(subject)
      subject.should_receive(:for_claimant).with(:dr_clam).and_return(subject)
      subject.should_receive(:for_entity).with(:a_luffly_pirate).and_return(subject)
      subject.should_receive(:for_processes).with([:jasmine, :mulan]).and_return(subject)
      subject.should_receive(:completable).with(true).and_return(subject)
      subject.should_receive(:with_fields).with({ :horse => :giant_pony, :pie => :silly_cake }).and_return(subject)
      subject.where({
        :available => true,
        :nickname => :nicholas,
        :roles => [:dinner, :barca],
        :unclaimed => true,
        :claimed => true,
        :claimant => :dr_clam,
        :entity => :a_luffly_pirate,
        :processes => [:jasmine, :mulan],
        :completable => true,
        :horse => :giant_pony,
        :pie => :silly_cake
      })
    end
  end
end
