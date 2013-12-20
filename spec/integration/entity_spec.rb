require File.expand_path(File.join(fixtures_path, 'entities', 'furby'))

describe 'Entity Module' do
  let(:app_root) {
    File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories'))
  }

  before :each do
    Bumbleworks.reset!
    load File.join(app_root, 'full_initializer.rb')
  end

  describe 'launching a process' do
    it 'assigns entity to process and subsequent tasks' do
      furby = Furby.new('12345')
      furby.launch_process(:make_honey)
      Bumbleworks.dashboard.wait_for(:dave)
      task = Bumbleworks::Task.for_role('dave').first
      task.entity.should == furby
    end

    it 'links processes with identifiers' do
      furby = Furby.new('12345')
      process = furby.launch_process(:make_honey)
      furby.processes.should == {
        :make_honey => process
      }
    end

    it 'persists process identifier' do
      furby = Furby.new('12345')
      process = furby.launch_process(:make_honey)
      furby.make_honey_process_identifier.should == process.wfid
    end
  end
end