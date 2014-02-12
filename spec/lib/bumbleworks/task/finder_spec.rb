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

  describe '#check_queries' do
    it 'raises an exception in case a query type is unrecognized' do
      subject.instance_variable_set(:@queries, ['not a real query'])
      expect {
        subject.check_queries(:wi, :task)
      }.to raise_error("Unrecognized query type")
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

  describe '#add_subfinder' do
    it 'adds given finder as new sub' do
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      finder = subject.add_subfinder(
        Bumbleworks::Task::Finder.new.for_role(:cat)
      )
      finder.map(&:nickname).should =~ [
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
      tasks = described_class.new(MyOwnTask).all
      tasks.should be_all { |t| t.class == MyOwnTask }
      Object.send(:remove_const, :MyOwnTask)
    end
  end

  describe '#available' do
    it 'adds both unclaimed and completable filters' do
      subject.should_receive(:where_all).with(:unclaimed => true, :completable => true).and_return(subject)
      subject.available
    end

    it 'adds OR-ed claimed and not-completable filters if passed false' do
      subject.should_receive(:where_any).with(:claimed => true, :completable => false).and_return(subject)
      subject.available(false)
    end
  end

  describe '#unavailable' do
    it 'checks if not available' do
      subject.should_receive(:available).with(false).and_return(subject)
      subject.unavailable
    end

    it 'checks if available when passed false' do
      subject.should_receive(:available).with(true).and_return(subject)
      subject.unavailable(false)
    end
  end

  [:all, :any].each do |join_type|
    describe "#where_#{join_type}" do
      it "sets join to #{join_type} if no args" do
        subject.should_receive(:join=).with(join_type)
        subject.send(:"where_#{join_type}")
      end

      it "calls where with :#{join_type} type if args" do
        subject.should_receive(:where).with(:filters, join_type)
        subject.send(:"where_#{join_type}", :filters)
      end
    end
  end

  describe '#where' do
    it 'creates a new finder and adds it to queries, when join type mismatch' do
      parent = described_class.new(:dummy_task_class).where_all
      child = described_class.new
      described_class.stub(:new).with(:dummy_task_class).and_return(child)
      child.should_receive(:where_any)
      child.should_receive(:available).and_return(child)
      child.should_receive(:unavailable).and_return(child)
      child.should_receive(:by_nickname).with(:nicholas).and_return(child)
      child.should_receive(:for_roles).with([:dinner, :barca]).and_return(child)
      child.should_receive(:unclaimed).and_return(child)
      child.should_receive(:claimed).and_return(child)
      child.should_receive(:for_claimant).with(:dr_clam).and_return(child)
      child.should_receive(:for_entity).with(:a_luffly_pirate).and_return(child)
      child.should_receive(:for_processes).with([:jasmine, :mulan]).and_return(child)
      child.should_receive(:completable).with(true).and_return(child)
      child.should_receive(:with_fields).with(:horse => :giant_pony).and_return(child)
      child.should_receive(:with_fields).with(:pie => :silly_cake).and_return(child)
      parent.should_receive(:add_subfinder).with(child).and_return(parent)
      parent.where({
        :available => true,
        :unavailable => true,
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
      }, :any).should == parent
    end

    it 'adds queries to current finder, when join type matches' do
      subject.should_receive(:available).and_return(subject)
      subject.should_receive(:unavailable).and_return(subject)
      subject.should_receive(:by_nickname).with(:nicholas).and_return(subject)
      subject.should_receive(:for_roles).with([:dinner, :barca]).and_return(subject)
      subject.should_receive(:unclaimed).and_return(subject)
      subject.should_receive(:claimed).and_return(subject)
      subject.should_receive(:for_claimant).with(:dr_clam).and_return(subject)
      subject.should_receive(:for_entity).with(:a_luffly_pirate).and_return(subject)
      subject.should_receive(:for_processes).with([:jasmine, :mulan]).and_return(subject)
      subject.should_receive(:completable).with(true).and_return(subject)
      subject.should_receive(:with_fields).with(:horse => :giant_pony).and_return(subject)
      subject.should_receive(:with_fields).with(:pie => :silly_cake).and_return(subject)
      subject.should_receive(:add_subfinder).never
      subject.where({
        :available => true,
        :unavailable => true,
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
      }).should == subject
    end
  end
end
