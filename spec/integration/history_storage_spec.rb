describe 'History storage' do
  let(:app_root) {
    File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories'))
  }

  class HashStorageWithHistory < Bumbleworks::HashStorage
    def self.allow_history_storage?
      true
    end
  end

  before :each do
    Bumbleworks.reset!
  end

  context 'when storage allows storing history' do
    before :each do
      Bumbleworks.stub(:storage_adapter => HashStorageWithHistory)
      load File.join(app_root, 'full_initializer.rb')
    end

    it 'uses storage for history' do
      Bumbleworks.dashboard.history.should be_a(::Ruote::StorageHistory)
    end

    it 'keeps history of messages' do
      Bumbleworks::Ruote.storage.get_many('history').should be_empty
      wfid = Bumbleworks.launch!('make_honey')
      Bumbleworks.dashboard.wait_for(:dave)
      Bumbleworks::Ruote.storage.get_many('history').should_not be_empty
      Bumbleworks.dashboard.history.wfids.should include(wfid)
    end
  end

  context 'when storage does not allow storing history' do
    before :each do
      load File.join(app_root, 'full_initializer.rb')
    end

    it 'does not use storage for history' do
      Bumbleworks.dashboard.history.should be_a(::Ruote::DefaultHistory)
    end

    it 'keeps history of messages' do
      Bumbleworks.dashboard.history.all.should be_empty
      wfid = Bumbleworks.launch!('make_honey')
      Bumbleworks.dashboard.wait_for(:dave)
      Bumbleworks.dashboard.history.all.should_not be_empty
      Bumbleworks.dashboard.history.wfids.should include(wfid)
    end
  end
end