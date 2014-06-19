require File.expand_path(File.join(fixtures_path, 'entities', 'rainbow_loom'))

describe 'Entity Module' do
  let(:app_root) {
    File.expand_path(File.join(fixtures_path, 'apps', 'with_default_directories'))
  }

  before :each do
    load File.join(app_root, 'full_initializer.rb')
  end

  describe 'including' do
    it 'registers entity with Bumbleworks' do
      Bumbleworks.entity_classes = [:geese]
      FirstNewClass = Class.new { include Bumbleworks::Entity }
      SecondNewClass = Class.new { include Bumbleworks::Entity }
      expect(Bumbleworks.entity_classes).to eq([:geese, FirstNewClass, SecondNewClass])
    end
  end

  describe 'process control' do
    it 'launching assigns entity to process and subsequent tasks' do
      rainbow_loom = RainbowLoom.new('12345')
      process = rainbow_loom.launch_process(:make_honey)
      Bumbleworks.dashboard.wait_for(:dave)
      task = Bumbleworks::Task.for_role('dave').first
      expect(task.entity).to eq(rainbow_loom)
      expect(process.entity).to eq(rainbow_loom)
    end

    it 'launching links processes with identifiers' do
      rainbow_loom = RainbowLoom.new('12345')
      process = rainbow_loom.launch_process(:make_honey)
      expect(rainbow_loom.processes_by_name).to eq({
        :make_honey => process,
        :make_molasses => nil
      })
    end

    it 'persists process identifier' do
      rainbow_loom = RainbowLoom.new('12345')
      process = rainbow_loom.launch_process(:make_honey)
      expect(rainbow_loom.make_honey_process_identifier).to eq(process.wfid)
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
      expect(process.tasks.first['yum']).to eq("2 and orange")
    end
  end
end