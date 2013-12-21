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
      furby.processes_by_name.should == {
        :make_honey => process
      }
    end

    it 'persists process identifier' do
      furby = Furby.new('12345')
      process = furby.launch_process(:make_honey)
      furby.make_honey_process_identifier.should == process.wfid
    end
  end

  describe 'using the entity interactor participant' do
    it 'calls a method on the entity' do
      Bumbleworks.define_process 'here_we_go' do
        tell_entity :to => 'cook_it_up', :with => [2, 'orange'], :and_save_as => 'yum'
        critic :task => 'checkit_that_foods'
      end
      furby = Furby.new('12345')
      process = Bumbleworks.launch!('here_we_go', :entity => furby)
      Bumbleworks.dashboard.wait_for(:critic)
      process.tasks.first['yum'].should == "2 and orange"
    end
  end
end