require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))

describe 'Entity Module' do
  let(:app_root) {
    File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories'))
  }

  before :each do
    Bumbleworks.reset!
    load File.join(app_root, 'full_initializer.rb')
  end

  describe 'process control' do
    it 'launching assigns entity to process and subsequent tasks' do
      rainbow_loom = RainbowLoom.new('12345')
      process = rainbow_loom.launch_process(:make_honey)
      Bumbleworks.dashboard.wait_for(:dave)
      task = Bumbleworks::Task.for_role('dave').first
      task.entity.should == rainbow_loom
      process.entity.should == rainbow_loom
    end

    it 'launching links processes with identifiers' do
      rainbow_loom = RainbowLoom.new('12345')
      process = rainbow_loom.launch_process(:make_honey)
      rainbow_loom.processes_by_name.should == {
        :make_honey => process,
        :make_molasses => nil
      }
    end

    it 'persists process identifier' do
      rainbow_loom = RainbowLoom.new('12345')
      process = rainbow_loom.launch_process(:make_honey)
      rainbow_loom.make_honey_process_identifier.should == process.wfid
    end
  end

  describe 'using the entity interactor participant' do
    it 'calls a method on the entity' do
      Bumbleworks.define_process 'here_we_go' do
        tell_entity :to => 'cook_it_up', :with => [2, 'orange'], :and_save_as => 'yum'
        critic :task => 'checkit_that_foods'
      end
      rainbow_loom = RainbowLoom.new('12345')
      process = Bumbleworks.launch!('here_we_go', :entity => rainbow_loom)
      Bumbleworks.dashboard.wait_for(:critic)
      process.tasks.first['yum'].should == "2 and orange"
    end
  end
end