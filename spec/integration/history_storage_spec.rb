describe 'History storage' do
  let(:app_root) {
    File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories'))
  }

  class HashStorageWithHistory < Bumbleworks::HashStorage
    def self.allow_history_storage?
      true
    end
  end

  context 'when storage allows storing history' do
    before :each do
      allow(Bumbleworks).to receive_messages(:storage_adapter => HashStorageWithHistory)
      load File.join(app_root, 'full_initializer.rb')
    end

    it 'uses storage for history' do
      expect(Bumbleworks.dashboard.history).to be_a(::Ruote::StorageHistory)
    end

    it 'keeps history of messages' do
      expect(Bumbleworks::Ruote.storage.get_many('history')).to be_empty
      process = Bumbleworks.launch!('make_honey')
      Bumbleworks.dashboard.wait_for(:dave)
      expect(Bumbleworks::Ruote.storage.get_many('history')).not_to be_empty
      expect(Bumbleworks.dashboard.history.wfids).to include(process.wfid)
    end
  end

  context 'when storage does not allow storing history' do
    before :each do
      load File.join(app_root, 'full_initializer.rb')
    end

    it 'does not use storage for history' do
      expect(Bumbleworks.dashboard.history).to be_a(::Ruote::DefaultHistory)
    end

    it 'keeps history of messages' do
      expect(Bumbleworks.dashboard.history.all).to be_empty
      process = Bumbleworks.launch!('make_honey')
      Bumbleworks.dashboard.wait_for(:dave)
      expect(Bumbleworks.dashboard.history.all).not_to be_empty
      expect(Bumbleworks.dashboard.history.wfids).to include(process.wfid)
    end
  end
end