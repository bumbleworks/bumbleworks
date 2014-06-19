describe Bumbleworks::User do
  let(:user_class) { Class.new { include Bumbleworks::User } }
  let(:subject) { user_class.new }

  describe '#claim_token' do
    it 'returns username by default' do
      allow(subject).to receive_messages(:username => 'nerfobot')
      expect(subject.claim_token).to eq('nerfobot')
    end

    it 'returns email if no username' do
      allow(subject).to receive_messages(:email => 'fromp@nougatcountry.com')
      expect(subject.claim_token).to eq('fromp@nougatcountry.com')
    end

    it 'prefers username to email when both respond' do
      allow(subject).to receive_messages(:username => 'dumb', :email => 'moar dumb')
      expect(subject.claim_token).to eq('dumb')
    end

    it 'returns nil if method defined' do
      allow(subject).to receive(:username)
      expect(subject.claim_token).to be_nil
    end

    it 'raises exception if neither username nor email defined' do
      expect {
        subject.claim_token
      }.to raise_error(Bumbleworks::User::NoClaimTokenMethodDefined)
    end
  end

  describe '#claim' do
    before(:each) do
      allow(subject).to receive_messages(:role_identifiers => ['snoogat'])
      allow(subject).to receive_messages(:claim_token => "the umpire of snorts")
    end

    it 'claims a task if authorized' do
      task = double('task', :role => 'snoogat')
      expect(task).to receive(:claim).with("the umpire of snorts")
      subject.claim(task)
    end

    it 'raises exception if unauthorized' do
      task = double('task', :role => 'fashbone')
      expect(task).to receive(:claim).never
      expect {
        subject.claim(task)
      }.to raise_error(Bumbleworks::User::UnauthorizedClaimAttempt)
    end

    it 'raises exception if already claimed by another' do
      task = double('task', :role => 'snoogat')
      expect(task).to receive(:claim).and_raise(Bumbleworks::Task::AlreadyClaimed)
      expect {
        subject.claim(task)
      }.to raise_error(Bumbleworks::Task::AlreadyClaimed)
    end

    describe '!' do
      it 'resets even if claimed by another' do
        task = double('task', :role => 'snoogat', :claimed? => true, :claimant => 'fumbo the monfey')
        expect(task).to receive(:release).ordered
        expect(task).to receive(:claim).with("the umpire of snorts").ordered
        subject.claim!(task)
      end

      it 'raises exception (and does not release) if unauthorized' do
        task = double('task', :role => 'fashbone')
        expect(task).to receive(:release).never
        expect(task).to receive(:claim).never
        expect {
          subject.claim!(task)
        }.to raise_error(Bumbleworks::User::UnauthorizedClaimAttempt)
      end
    end
  end

  describe '#release' do
    before(:each) do
      allow(subject).to receive_messages(:claim_token => "the umpire of snorts")
    end

    it 'releases a claimed task if claimant' do
      task = double('task', :claimed? => true, :claimant => "the umpire of snorts")
      expect(task).to receive(:release)
      subject.release(task)
    end

    it 'does nothing if task not claimed' do
      task = double('task', :claimed? => false)
      expect(task).to receive(:release).never
      subject.release(task)
    end

    it 'raises exception if not claimant' do
      task = double('task', :claimed? => true, :claimant => 'a castanet expert')
      expect(task).to receive(:release).never
      expect {
        subject.release(task)
      }.to raise_error(Bumbleworks::User::UnauthorizedReleaseAttempt)
    end

    describe '!' do
      it 'releases even if not claimant' do
        task = double('task', :claimed? => true, :claimant => 'a castanet expert')
        expect(task).to receive(:release)
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
      allow(subject).to receive_messages(:role_identifiers => ['role1', 'role2'])
    end

    it 'returns true if role_identifiers includes given role' do
      expect(subject.has_role?('role1')).to be_truthy
    end

    it 'returns false if role_identifiers does not include given role' do
      expect(subject.has_role?('role3')).to be_falsy
    end
  end

  describe '#authorized_tasks' do
    it 'returns task query for all tasks for user roles' do
      allow(subject).to receive_messages(:role_identifiers => ['goose', 'midget'])
      allow(Bumbleworks::Task).to receive(:for_roles).with(['goose', 'midget']).and_return(:all_the_tasks)
      expect(subject.authorized_tasks).to eq(:all_the_tasks)
    end
  end

  describe '#claimed_tasks' do
    it 'returns task query for all user claimed tasks' do
      allow(subject).to receive_messages(:claim_token => :yay_its_me)
      allow(Bumbleworks::Task).to receive(:for_claimant).with(:yay_its_me).and_return(:my_tasks)
      expect(subject.claimed_tasks).to eq(:my_tasks)
    end
  end

  describe '#available_tasks' do
    it 'returns authorized tasks filtered by available' do
      allow(subject).to receive_messages(:role_identifiers => ['goose', 'midget'])
      task_finder = double('task_finder')
      allow(task_finder).to receive_messages(:available => :only_the_available_tasks)
      allow(Bumbleworks::Task).to receive(:for_roles).with(['goose', 'midget']).and_return(task_finder)
      expect(subject.available_tasks).to eq(:only_the_available_tasks)
    end
  end
end