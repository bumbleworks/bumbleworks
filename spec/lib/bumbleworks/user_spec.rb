describe Bumbleworks::User do
  let(:user_class) { Class.new { include Bumbleworks::User } }
  let(:subject) { user_class.new }

  describe '#claim_token' do
    it 'returns username by default' do
      subject.stub(:username => 'nerfobot')
      subject.claim_token.should == 'nerfobot'
    end

    it 'returns email if no username' do
      subject.stub(:email => 'fromp@nougatcountry.com')
      subject.claim_token.should == 'fromp@nougatcountry.com'
    end

    it 'prefers username to email when both respond' do
      subject.stub(:username => 'dumb', :email => 'moar dumb')
      subject.claim_token.should == 'dumb'
    end

    it 'returns nil if method defined' do
      subject.stub(:username)
      subject.claim_token.should be_nil
    end

    it 'raises exception if neither username nor email defined' do
      expect {
        subject.claim_token
      }.to raise_error(Bumbleworks::User::NoClaimTokenMethodDefined)
    end
  end

  describe '#claim' do
    before(:each) do
      subject.stub(:role_identifiers => ['snoogat'])
      subject.stub(:claim_token => "the umpire of snorts")
    end

    it 'claims a task if authorized' do
      task = double('task', :role => 'snoogat')
      task.should_receive(:claim).with("the umpire of snorts")
      subject.claim(task)
    end

    it 'raises exception if unauthorized' do
      task = double('task', :role => 'fashbone')
      task.should_receive(:claim).never
      expect {
        subject.claim(task)
      }.to raise_error(Bumbleworks::User::UnauthorizedClaimAttempt)
    end

    it 'raises exception if already claimed by another' do
      task = double('task', :role => 'snoogat')
      task.should_receive(:claim).and_raise(Bumbleworks::Task::AlreadyClaimed)
      expect {
        subject.claim(task)
      }.to raise_error(Bumbleworks::Task::AlreadyClaimed)
    end

    describe '!' do
      it 'resets even if claimed by another' do
        task = double('task', :role => 'snoogat', :claimed? => true, :claimant => 'fumbo the monfey')
        task.should_receive(:release).ordered
        task.should_receive(:claim).with("the umpire of snorts").ordered
        subject.claim!(task)
      end
    end
  end

  describe '#release' do
    before(:each) do
      subject.stub(:claim_token => "the umpire of snorts")
    end

    it 'releases a claimed task if claimant' do
      task = double('task', :claimed? => true, :claimant => "the umpire of snorts")
      task.should_receive(:release)
      subject.release(task)
    end

    it 'does nothing if task not claimed' do
      task = double('task', :claimed? => false)
      task.should_receive(:release).never
      subject.release(task)
    end

    it 'raises exception if not claimant' do
      task = double('task', :claimed? => true, :claimant => 'a castanet expert')
      task.should_receive(:release).never
      expect {
        subject.release(task)
      }.to raise_error(Bumbleworks::User::UnauthorizedReleaseAttempt)
    end

    describe '!' do
      it 'releases even if not claimant' do
        task = double('task', :claimed? => true, :claimant => 'a castanet expert')
        task.should_receive(:release)
        subject.release!(task)
      end
    end
  end

  describe '#role_identifiers' do
    it 'raises exception by default' do
      expect {
        subject.role_identifiers
      }.to raise_error(Bumbleworks::User::NoRoleIdentifiersMethodDefined)
    end
  end

  describe '#has_role?' do
    before(:each) do
      subject.stub(:role_identifiers => ['role1', 'role2'])
    end

    it 'returns true if role_identifiers includes given role' do
      subject.has_role?('role1').should be_true
    end

    it 'returns false if role_identifiers does not include given role' do
      subject.has_role?('role3').should be_false
    end
  end

  describe '#authorized_tasks' do
    it 'returns task query for all tasks for user roles' do
      subject.stub(:role_identifiers => ['goose', 'midget'])
      Bumbleworks::Task.stub(:for_roles).with(['goose', 'midget']).and_return(:all_the_tasks)
      subject.authorized_tasks.should == :all_the_tasks
    end
  end

  describe '#claimed_tasks' do
    it 'returns task query for all user claimed tasks' do
      subject.stub(:claim_token => :yay_its_me)
      Bumbleworks::Task.stub(:for_claimant).with(:yay_its_me).and_return(:my_tasks)
      subject.claimed_tasks.should == :my_tasks
    end
  end

  describe '#available_tasks' do
    it 'returns authorized tasks filtered by available' do
      subject.stub(:role_identifiers => ['goose', 'midget'])
      task_finder = double('task_finder')
      task_finder.stub(:available => :only_the_available_tasks)
      Bumbleworks::Task.stub(:for_roles).with(['goose', 'midget']).and_return(task_finder)
      subject.available_tasks.should == :only_the_available_tasks
    end
  end
end