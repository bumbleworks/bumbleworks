describe Bumbleworks::Task do
  let(:workflow_item) {Ruote::Workitem.new('fields' => {'params' => {'task' => 'go_to_work'} })}

  before :each do
    Bumbleworks.reset!
    Bumbleworks.storage = {}
    Bumbleworks::Ruote.register_participants
    Bumbleworks.start_worker!
  end

  it_behaves_like "an entity holder" do
    let(:holder) { described_class.new(workflow_item) }
    let(:storage_workitem) { Bumbleworks::Workitem.new(workflow_item) }
  end

  describe '#not_completable_error_message' do
    it 'defaults to generic message' do
      task = described_class.new(workflow_item)
      task.not_completable_error_message.should ==
        "This task is not currently completable."
    end
  end

  describe '.autoload_all' do
    it 'autoloads all task modules in directory' do
      Bumbleworks.root = File.join(fixtures_path, 'apps', 'with_default_directories')
      Object.should_receive(:autoload).with(:MakeSomeHoneyTask,
        File.join(Bumbleworks.root, 'tasks', 'make_some_honey_task.rb'))
      Object.should_receive(:autoload).with(:TasteThatMolassesTask,
        File.join(Bumbleworks.root, 'tasks', 'taste_that_molasses_task.rb'))
      described_class.autoload_all
    end

    it 'does nothing if using default path and directory does not exist' do
      Bumbleworks.root = File.join(fixtures_path, 'apps', 'minimal')
      described_class.autoload_all
    end

    it 'raises exception if using custom path and participants file does not exist' do
      Bumbleworks.root = File.join(fixtures_path, 'apps', 'minimal')
      Bumbleworks.tasks_directory = 'oysters'
      expect {
        described_class.autoload_all
      }.to raise_error(Bumbleworks::InvalidSetting)
    end
  end

  describe '#completable?' do
    it 'defaults to true on base task' do
      described_class.new(workflow_item).should be_completable
    end
  end

  describe '.new' do
    it 'raises an error if workitem is nil' do
      expect {
        described_class.new(nil)
      }.to raise_error(ArgumentError, "Not a valid workitem")
    end

    it 'raises an error if workitem not a Ruote::Workitem' do
      expect {
        described_class.new('a string!')
      }.to raise_error(ArgumentError, "Not a valid workitem")
    end

    it 'succeeds when given workitem' do
      expect {
        described_class.new(workflow_item)
      }.not_to raise_error
    end

    it 'extends new object with task module' do
      described_class.any_instance.should_receive(:extend_module)
      described_class.new(workflow_item)
    end
  end

  describe '#reload' do
    it 'reloads the workitem from the storage participant' do
      task = described_class.new(workflow_item)
      task.stub(:sid).and_return(:the_sid)
      Bumbleworks.dashboard.storage_participant.should_receive(
        :[]).with(:the_sid).and_return(:amazing_workitem)
      task.reload
      task.instance_variable_get(:@workitem).should == :amazing_workitem
    end
  end

  [:before, :after].each do |phase|
    describe "#call_#{phase}_hooks" do
      it "calls #{phase} hooks on task and all observers" do
        observer1, observer2 = double('observer1'), double('observer2')
        Bumbleworks.observers = [observer1, observer2]
        task = described_class.new(workflow_item)
        task.should_receive(:"#{phase}_snoogle").with(:chachunga, :faloop)
        observer1.should_receive(:"#{phase}_snoogle").with(:chachunga, :faloop)
        observer2.should_receive(:"#{phase}_snoogle").with(:chachunga, :faloop)
        task.send(:"call_#{phase}_hooks", :snoogle, :chachunga, :faloop)
      end
    end
  end

  describe '#on_dispatch' do
    before :each do
      Bumbleworks.define_process 'planting_a_noodle' do
        concurrence do
          horse_feeder :task => 'give_the_horse_a_bon_bon'
        end
      end
    end

    it 'is called when task is dispatched' do
      described_class.any_instance.should_receive(:on_dispatch)
      Bumbleworks.launch!('planting_a_noodle')
      Bumbleworks.dashboard.wait_for(:horse_feeder)
    end

    it 'logs dispatch' do
      Bumbleworks.launch!('planting_a_noodle')
      Bumbleworks.dashboard.wait_for(:horse_feeder)
      task = described_class.for_role('horse_feeder').first
      log_entry = Bumbleworks.logger.entries.last[:entry]
      log_entry[:action].should == :dispatch
      log_entry[:target_type].should == 'Task'
      log_entry[:target_id].should == task.id
    end

    it 'calls after hooks' do
      task = described_class.new(workflow_item)
      task.stub(:log)
      task.should_receive(:call_after_hooks).with(:dispatch)
      task.on_dispatch
    end
  end

  describe '#extend_module' do
    it 'extends with base module and task module' do
      task = described_class.new(workflow_item)
      task.should_receive(:task_module).and_return(:task_module_double)
      task.should_receive(:extend).with(Bumbleworks::Task::Base).ordered
      task.should_receive(:extend).with(:task_module_double).ordered
      task.extend_module
    end

    it 'extends only with base module if no nickname' do
      task = described_class.new(workflow_item)
      task.stub(:nickname).and_return(nil)
      task.should_receive(:extend).with(Bumbleworks::Task::Base)
      task.extend_module
    end

    it 'extends only with base module if task module does not exist' do
      task = described_class.new(workflow_item)
      task.should_receive(:extend).with(Bumbleworks::Task::Base)
      task.extend_module
    end
  end

  describe '#task_module' do
    it 'returns nil if no nickname' do
      task = described_class.new(workflow_item)
      task.stub(:nickname).and_return(nil)
      task.task_module.should be_nil
    end

    it 'returns constantized task nickname with "Task" appended' do
      task = described_class.new(workflow_item)
      Bumbleworks::Support.stub(:constantize).with("GoToWorkTask").and_return(:the_task_module)
      task.task_module.should == :the_task_module
    end
  end

  describe '#id' do
    it 'returns the sid from the workitem' do
      workflow_item.stub(:sid).and_return(:an_exciting_id)
      described_class.new(workflow_item).id.should == :an_exciting_id
    end
  end

  describe '.find_by_id' do
    it 'returns the task for the given id' do
      Bumbleworks.define_process 'planting_a_noodle' do
        concurrence do
          noodle_gardener :task => 'plant_noodle_seed'
          horse_feeder :task => 'give_the_horse_a_bon_bon'
        end
      end
      Bumbleworks.launch!('planting_a_noodle')
      Bumbleworks.dashboard.wait_for(:horse_feeder)
      plant_noodle_seed_task = described_class.for_role('noodle_gardener').first
      give_the_horse_a_bon_bon_task = described_class.for_role('horse_feeder').first

      # checking for equality by comparing sid, which is the flow expression id
      # that identifies not only the expression, but its instance
      described_class.find_by_id(plant_noodle_seed_task.id).sid.should ==
        plant_noodle_seed_task.sid
      described_class.find_by_id(give_the_horse_a_bon_bon_task.id).sid.should ==
        give_the_horse_a_bon_bon_task.sid
    end

    it 'raises an error if id is nil' do
      expect {
        described_class.find_by_id(nil)
      }.to raise_error(described_class::MissingWorkitem)
    end

    it 'raises an error if workitem not found for given id' do
      expect {
        described_class.find_by_id('asdfasdf')
      }.to raise_error(described_class::MissingWorkitem)
    end

    it 'raises an error if id is unparseable by storage participant' do
      expect {
        described_class.find_by_id(:unparseable_because_i_am_a_symbol)
      }.to raise_error(described_class::MissingWorkitem)
    end
  end

  describe '.for_roles' do
    before :each do
      Bumbleworks.define_process 'lowering_penguin_self_esteem' do
        concurrence do
          heckler :task => 'comment_on_dancing_ability'
          mother :oh_no => 'this_is_not_a_task'
          mother :task => 'ignore_pleas_for_attention'
          father :task => 'sit_around_watching_penguin_tv'
        end
      end
      Bumbleworks.launch!('lowering_penguin_self_esteem')
    end

    it 'returns tasks for all given roles' do
      Bumbleworks.dashboard.wait_for(:father)
      tasks = described_class.for_roles(['heckler', 'mother'])
      tasks.should have(2).items
      tasks.map(&:nickname).should == [
        'comment_on_dancing_ability',
        'ignore_pleas_for_attention'
      ]
    end

    it 'returns empty array if no tasks found for given roles' do
      Bumbleworks.dashboard.wait_for(:father)
      described_class.for_roles(['elephant']).should be_empty
    end

    it 'returns empty array if given empty array' do
      Bumbleworks.dashboard.wait_for(:father)
      described_class.for_roles([]).should be_empty
    end

    it 'returns empty array if given nil' do
      Bumbleworks.dashboard.wait_for(:father)
      described_class.for_roles(nil).should be_empty
    end
  end

  describe '.for_processes' do
    before :each do
      Bumbleworks.define_process 'spunking' do
        concurrence do
          spunker :task => 'spunk'
          nonspunker :task => 'complain'
        end
      end
      Bumbleworks.define_process 'rooting' do
        concurrence do
          rooter :task => 'get_the_rooting_on'
          armchair_critic :task => 'scoff'
        end
      end
      @spunking_process = Bumbleworks.launch!('spunking')
      @rooting_process_1 = Bumbleworks.launch!('rooting')
      @rooting_process_2 = Bumbleworks.launch!('rooting')
      Bumbleworks.dashboard.wait_for(:armchair_critic)
    end

    it 'returns tasks for given processes' do
      spunking_tasks = described_class.for_processes([@spunking_process])
      rooting_tasks = described_class.for_processes([@rooting_process_1])
      tasks_for_both = described_class.for_processes([@spunking_process, @rooting_process_1])

      spunking_tasks.map(&:nickname).should =~ ['spunk', 'complain']
      rooting_tasks.map(&:nickname).should =~ ['get_the_rooting_on', 'scoff']
      tasks_for_both.map(&:nickname).should =~ ['spunk', 'complain', 'get_the_rooting_on', 'scoff']
    end

    it 'works with process ids as well' do
      spunking_tasks = described_class.for_processes([@spunking_process.id])
      spunking_tasks.map(&:nickname).should =~ ['spunk', 'complain']
    end

    it 'returns empty array when no tasks for given process id' do
      described_class.for_processes(['boop']).should be_empty
    end

    it 'returns empty array if given empty array' do
      described_class.for_processes([]).should be_empty
    end

    it 'returns empty array if given nil' do
      described_class.for_processes(nil).should be_empty
    end
  end

  describe '.for_process' do
    it 'acts as shortcut to .for_processes with one process' do
      described_class::Finder.any_instance.should_receive(:for_processes).with([:one_guy]).and_return(:aha)
      described_class.for_process(:one_guy).should == :aha
    end
  end

  describe '.for_role' do
    it 'returns all tasks for given role' do
      Bumbleworks.define_process 'chalking' do
        concurrence do
          chalker :task => 'make_chalk_drawings'
          chalker :task => 'chalk_it_good_baby'
          hagrid :task => 'moan_endearingly'
        end
      end
      Bumbleworks.launch!('chalking')
      Bumbleworks.dashboard.wait_for(:hagrid)

      tasks = described_class.for_role('chalker')
      tasks.map(&:nickname).should == [
        'make_chalk_drawings',
        'chalk_it_good_baby'
      ]
    end
  end

  describe '.unclaimed' do
    it 'returns all unclaimed tasks' do
      Bumbleworks.define_process 'dog-lifecycle' do
        concurrence do
          dog :task => 'eat'
          dog :task => 'bark'
          dog :task => 'pet_dog'
          cat :task => 'skip_and_jump'
        end
        dog :task => 'nap'
      end
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      @unclaimed = described_class.unclaimed
      @unclaimed.map(&:nickname).should =~ ['eat', 'bark', 'pet_dog', 'skip_and_jump']
      described_class.all.each do |t|
        t.claim('radish') unless ['pet_dog', 'bark'].include?(t.nickname)
      end
      @unclaimed = described_class.unclaimed
      @unclaimed.map(&:nickname).should =~ ['pet_dog', 'bark']
    end
  end

  describe '.claimed' do
    it 'returns all claimed tasks' do
      Bumbleworks.define_process 'dog-lifecycle' do
        concurrence do
          dog :task => 'eat'
          dog :task => 'bark'
          dog :task => 'pet_dog'
          cat :task => 'skip_and_jump'
        end
        dog :task => 'nap'
      end
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      described_class.claimed.should be_empty
      described_class.all.each_with_index do |t, i|
        t.claim("radish_#{i}") unless ['pet_dog', 'bark'].include?(t.nickname)
      end
      @claimed = described_class.claimed
      @claimed.map(&:nickname).should =~ ['eat', 'skip_and_jump']
    end
  end

  describe '.completable' do
    it 'filters by completability' do
      module WuggleHandsTask
        def completable?
          false
        end
      end

      Bumbleworks.define_process 'hand_waggling' do
        concurrence do
          a_fella :task => 'waggle_hands'
          a_monkey :task => 'wuggle_hands'
          a_lady :task => 'wiggle_hands'
        end
      end
      Bumbleworks.launch!('hand_waggling')
      Bumbleworks.dashboard.wait_for(:a_lady)
      tasks = described_class.completable
      tasks.should have(2).items
      tasks.map { |t| [t.role, t.nickname] }.should == [
        ['a_fella', 'waggle_hands'],
        ['a_lady', 'wiggle_hands']
      ]
      tasks = described_class.completable(false)
      tasks.should have(1).item
      tasks.map { |t| [t.role, t.nickname] }.should == [
        ['a_monkey', 'wuggle_hands']
      ]
    end
  end

  describe '.all' do
    before :each do
      Bumbleworks.define_process 'dog-lifecycle' do
        concurrence do
          dog_teeth :task => 'eat'
          dog_mouth :task => 'bark'
          everyone :task => 'pet_dog'
          the_universe_is_wonderful
          dog_legs :task => 'skip_and_jump'
        end
        dog_brain :task => 'nap'
      end
      Bumbleworks.launch!('dog-lifecycle')
    end

    it 'returns all tasks (with task param) in queue regardless of role' do
      Bumbleworks.dashboard.wait_for(:dog_legs)
      tasks = described_class.all
      tasks.should have(4).items
      tasks.map { |t| [t.role, t.nickname] }.should == [
        ['dog_teeth', 'eat'],
        ['dog_mouth', 'bark'],
        ['everyone', 'pet_dog'],
        ['dog_legs', 'skip_and_jump']
      ]
    end

    it 'uses subclass for generation of tasks' do
      class MyOwnTask < Bumbleworks::Task; end
      Bumbleworks.dashboard.wait_for(:dog_legs)
      tasks = MyOwnTask.all
      tasks.should be_all { |t| t.class == MyOwnTask }
      Object.send(:remove_const, :MyOwnTask)
    end
  end

  describe '#[], #[]=' do
    subject{described_class.new(workflow_item)}
    it 'sets values on workitem fields' do
      subject['hive'] = 'bees at work'
      workflow_item.fields['hive'].should == 'bees at work'
    end

    it 'retuns value from workitem params' do
      workflow_item.fields['nest'] = 'queen resting'
      subject['nest'].should == 'queen resting'
    end
  end

  describe '#nickname' do
    it 'returns the "task" param' do
      described_class.new(workflow_item).nickname.should == 'go_to_work'
    end

    it 'is immutable; cannot be changed by modified the param' do
      task = described_class.new(workflow_item)
      task.nickname.should == 'go_to_work'
      task.params['task'] = 'what_is_wrong_with_you?'
      task.nickname.should == 'go_to_work'
    end
  end

  describe '#role' do
    it 'returns the workitem participant_name' do
      Bumbleworks.define_process 'planting_a_noodle' do
        noodle_gardener :task => 'plant_noodle_seed'
      end
      Bumbleworks.launch!('planting_a_noodle')
      Bumbleworks.dashboard.wait_for(:noodle_gardener)
      described_class.all.first.role.should == 'noodle_gardener'
    end
  end

  describe '.for_claimant' do
    it 'returns all tasks claimed by given claimant' do
      Bumbleworks.define_process 'dog-lifecycle' do
        concurrence do
          dog :task => 'eat'
          dog :task => 'bark'
          dog :task => 'pet_dog'
          the_universe_is_wonderful
          cat :task => 'skip_and_jump'
        end
        dog :task => 'nap'
      end
      Bumbleworks.launch!('dog-lifecycle')
      Bumbleworks.dashboard.wait_for(:cat)
      described_class.for_claimant('radish').should be_empty
      described_class.all.each do |t|
        t.claim('radish') unless t.nickname == 'pet_dog'
      end
      @tasks = described_class.for_claimant('radish')
      @tasks.should have(3).items
      @tasks.map(&:nickname).should =~ ['eat', 'bark', 'skip_and_jump']
    end
  end

  describe '.with_fields' do
    it 'returns all tasks with given fields' do
      Bumbleworks.define_process 'divergination' do
        concurrence do
          sequence do
            set 'bumby' => 'fancy'
            bumber :task => 'wear_monocle'
          end
          sequence do
            set 'bumby' => 'not_fancy'
            concurrence do
              bumber :task => 'wear_natties'
              loofer :task => 'snuffle'
            end
          end
        end
      end
      Bumbleworks.launch!('divergination', :grumbles => true)
      Bumbleworks.dashboard.wait_for(:loofer)
      described_class.with_fields(:grumbles => true).count.should == 3
      described_class.with_fields(:bumby => 'fancy').count.should == 1
      described_class.with_fields(:bumby => 'not_fancy').count.should == 2
      described_class.with_fields(:grumbles => false, :bumby => 'not_fancy').should be_empty
      described_class.with_fields(:what => 'ever').should be_empty
    end
  end

  describe '.for_entity' do
    it 'returns all tasks associated with given entity' do
      fake_sandwich = OpenStruct.new(:identifier => 'rubies')
      Bumbleworks.define_process 'existential_pb_and_j' do
        concurrence do
          sandwich :task => 'be_made'
          sandwich :task => 'contemplate_being'
        end
      end
      Bumbleworks.launch!('existential_pb_and_j', :entity => fake_sandwich)
      Bumbleworks.dashboard.wait_for(:sandwich)
      tasks = described_class.for_entity(fake_sandwich)
      tasks.should have(2).items
    end
  end

  context '.by_nickname' do
    it 'returns all tasks with given nickname' do
      Bumbleworks.define_process 'animal_disagreements' do
        concurrence do
          turtle :task => 'be_a_big_jerk'
          goose :task => 'punch_turtle'
          rabbit :task => 'punch_turtle'
        end
      end
      Bumbleworks.launch!('animal_disagreements')
      Bumbleworks.dashboard.wait_for(:rabbit)
      tasks = described_class.by_nickname('punch_turtle')
      tasks.should have(2).items
      tasks.map(&:role).should =~ ['goose', 'rabbit']
    end
  end

  context 'claiming things' do
    before :each do
      Bumbleworks.define_process 'planting_a_noodle' do
        noodle_gardener :task => 'plant_noodle_seed'
      end
      Bumbleworks.launch!('planting_a_noodle')
      Bumbleworks.dashboard.wait_for(:noodle_gardener)
      @task = described_class.for_role('noodle_gardener').first
      @task.claim('boss')
    end

    describe '#claim' do
      it 'sets token on "claimant" param' do
        @task.params['claimant'].should == 'boss'
      end

      it 'sets claimed_at param' do
        @task.params['claimed_at'].should_not be_nil
      end

      it 'raises an error if already claimed by someone else' do
        expect{@task.claim('peon')}.to raise_error described_class::AlreadyClaimed
      end

      it 'does not raise an error if attempting to claim by same token' do
        expect{@task.claim('boss')}.not_to raise_error
      end

      it 'calls before_claim and after_claim callbacks' do
        task = described_class.new(workflow_item)
        task.stub(:log)
        task.should_receive(:before_claim).with(:doctor_claim).ordered
        task.should_receive(:set_claimant).ordered
        task.should_receive(:after_claim).with(:doctor_claim).ordered
        task.claim(:doctor_claim)
      end

      it 'logs event' do
        log_entry = Bumbleworks.logger.entries.last[:entry]
        log_entry[:action].should == :claim
        log_entry[:actor].should == 'boss'
      end
    end

    describe '#claimant' do
      it 'returns token of who has claim' do
        @task.claimant.should == 'boss'
      end
    end

    describe '#claimed_at' do
      it 'returns claimed_at param' do
        @task.claimed_at.should == @task.params['claimed_at']
      end
    end

    describe '#claimed?' do
      it 'returns true if claimed' do
        @task.claimed?.should be_true
      end

      it 'false otherwise' do
        @task.params['claimant'] = nil
        @task.claimed?.should be_false
      end
    end

    describe '#release' do
      it "release claim on workitem" do
        @task.should be_claimed
        @task.release
        @task.should_not be_claimed
      end

      it 'clears claimed_at param' do
        @task.release
        @task.params['claimed_at'].should be_nil
      end

      it 'calls with hooks' do
        @task.should_receive(:call_before_hooks).with(:release, 'boss').ordered
        @task.should_receive(:set_claimant).ordered
        @task.should_receive(:call_after_hooks).with(:release, 'boss').ordered
        @task.release
      end

      it 'logs event' do
        @task.release
        log_entry = Bumbleworks.logger.entries.last[:entry]
        log_entry[:action].should == :release
        log_entry[:actor].should == 'boss'
      end
    end
  end

  context 'updating workflow engine' do
    before :each do
      Bumbleworks.define_process 'dog-lifecycle' do
        dog_mouth :task => 'eat_dinner', :state => 'still cooking'
        dog_brain :task => 'cat_nap', :by => 'midnight'
      end
      Bumbleworks.launch!('dog-lifecycle')
    end

    describe '#update' do
      it 'saves fields and params, but does not proceed process' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['state'] = 'is ready'
        task.fields['meal'] = 'salted_rhubarb'
        task.update
        task = described_class.for_role('dog_mouth').first
        task.params['state'].should == 'is ready'
        task.fields['meal'].should == 'salted_rhubarb'
      end

      it 'calls with hooks' do
        task = described_class.new(workflow_item)
        task.stub(:log)
        task.should_receive(:call_before_hooks).with(:update, :argue_mints).ordered
        task.should_receive(:update_workitem).ordered
        task.should_receive(:call_after_hooks).with(:update, :argue_mints).ordered
        task.update(:argue_mints)
      end

      it 'logs event' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['claimant'] = :some_user
        task.update(:extra_data => :fancy)
        Bumbleworks.logger.entries.last.should == {
          :level => :info, :entry => {
            :actor => :some_user,
            :action => :update,
            :target_type => 'Task',
            :target_id => task.id,
            :metadata => {
              :extra_data => :fancy,
              :current_fields => task.fields
            }
          }
        }
      end
    end

    describe '#complete' do
      it 'saves fields and proceeds to next expression' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['state'] = 'is ready'
        task.fields['meal'] = 'root beer and a kite'
        task.complete
        described_class.for_role('dog_mouth').should be_empty
        event = Bumbleworks.dashboard.wait_for :dog_brain
        task = described_class.for_role('dog_brain').first
        task.params['state'].should be_nil
        task.fields['meal'].should == 'root beer and a kite'
      end

      it 'throws exception if task is not completable' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.stub(:completable?).and_return(false)
        task.stub(:not_completable_error_message).and_return('hogwash!')
        task.should_receive(:before_update).never
        task.should_receive(:before_complete).never
        task.should_receive(:proceed_workitem).never
        task.should_receive(:after_complete).never
        task.should_receive(:after_update).never
        expect {
          task.complete
        }.to raise_error(Bumbleworks::Task::NotCompletable, "hogwash!")
        described_class.for_role('dog_mouth').should_not be_empty
      end

      it 'calls update and complete callbacks' do
        task = described_class.new(workflow_item)
        task.stub(:log)
        task.should_receive(:call_before_hooks).with(:update, :argue_mints).ordered
        task.should_receive(:call_before_hooks).with(:complete, :argue_mints).ordered
        task.should_receive(:proceed_workitem).ordered
        task.should_receive(:call_after_hooks).with(:complete, :argue_mints).ordered
        task.should_receive(:call_after_hooks).with(:update, :argue_mints).ordered
        task.complete(:argue_mints)
      end

      it 'logs event' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['claimant'] = :some_user
        task.complete(:extra_data => :fancy)
        Bumbleworks.logger.entries.last.should == {
          :level => :info, :entry => {
            :actor => :some_user,
            :action => :complete,
            :target_type => 'Task',
            :target_id => task.id,
            :metadata => {
              :extra_data => :fancy,
              :current_fields => task.fields
            }
          }
        }
      end
    end
  end

  describe 'chained queries' do
    it 'allows for AND-ed chained finders' do
      module BeProudTask
        def completable?
          role == 'pink'
        end
      end

      Bumbleworks.define_process 'the_big_kachunko' do
        concurrence do
          red :task => 'be_really_mad'
          blue :task => 'be_a_bit_sad'
          yellow :task => 'be_scared'
          green :task => 'be_envious'
          green :task => 'be_proud'
          pink :task => 'be_proud'
        end
      end
      Bumbleworks.launch!('the_big_kachunko')
      Bumbleworks.dashboard.wait_for(:pink)
      described_class.by_nickname('be_really_mad').first.claim('crayon_box')
      described_class.by_nickname('be_a_bit_sad').first.claim('crayon_box')
      described_class.by_nickname('be_scared').first.claim('crayon_box')

      tasks = described_class.
        for_roles(['green', 'pink']).
        by_nickname('be_proud')
      tasks.should have(2).items
      tasks.map(&:nickname).should =~ ['be_proud', 'be_proud']

      tasks = described_class.
        for_roles(['green', 'pink', 'blue']).
        completable.
        by_nickname('be_proud')
      tasks.should have(1).items
      tasks.map(&:nickname).should =~ ['be_proud']
      tasks.first.role.should == 'pink'

      tasks = described_class.
        for_claimant('crayon_box').
        for_roles(['red', 'yellow', 'green'])
      tasks.should have(2).items
      tasks.map(&:nickname).should =~ ['be_really_mad', 'be_scared']

      tasks = described_class.
        for_claimant('crayon_box').
        by_nickname('be_a_bit_sad').
        for_role('blue')
      tasks.should have(1).item
      tasks.first.nickname.should == 'be_a_bit_sad'
    end
  end

  describe 'method missing' do
    it 'calls method on new Finder object' do
      described_class::Finder.any_instance.stub(:shabam!).with(:yay).and_return(:its_a_me)
      described_class.shabam!(:yay).should == :its_a_me
    end

    it 'falls back to method missing if no finder method' do
      expect {
        described_class.kerplunk!(:oh_no)
      }.to raise_error
    end
  end

  describe '.next_available' do
    it 'waits for one task to show up and returns it' do
      Bumbleworks.define_process "lazy_bum_and_cool_guy" do
        concurrence do
          cool_guy :task => 'get_it_going_man'
          sequence do
            wait '2s'
            bum :task => 'finally_get_a_round_tuit'
          end
        end
      end
      start_time = Time.now
      Bumbleworks.launch!('lazy_bum_and_cool_guy')
      task = described_class.for_role('bum').next_available
      end_time = Time.now
      task.nickname.should == 'finally_get_a_round_tuit'
      (end_time - start_time).should >= 2
    end

    it 'times out if task does not appear in time' do
      Bumbleworks.define_process "really_lazy_bum_and_cool_guy" do
        concurrence do
          cool_guy :task => 'good_golly_never_mind_you'
          sequence do
            wait '2s'
            bum :task => 'whatever_these_socks_are_tasty'
          end
        end
      end
      Bumbleworks.launch!('really_lazy_bum_and_cool_guy')
      expect {
        described_class.for_role('bum').next_available(:timeout => 0.5)
      }.to raise_error(Bumbleworks::Task::AvailabilityTimeout)
    end
  end

  describe '#humanize' do
    it "returns humanized version of task name when no entity" do
      task = described_class.new(workflow_item)
      task.humanize.should == 'Go to work'
    end

    it "returns humanized version of task name with entity" do
      task = described_class.new(workflow_item)
      task[:entity_id] = '45'
      task[:entity_type] = 'RhubarbSandwich'
      task.humanize.should == 'Go to work: Rhubarb sandwich 45'
    end

    it "returns humanized version of task name without entity if requested" do
      task = described_class.new(workflow_item)
      task[:entity_id] = '45'
      task[:entity_type] = 'RhubarbSandwich'
      task.humanize(:entity => false).should == 'Go to work'
    end
  end

  describe '#to_s' do
    it "is aliased to #titleize" do
      task = described_class.new(workflow_item)
      task.stub(:titleize).with(:the_args).and_return(:see_i_told_you_so)
      task.to_s(:the_args).should == :see_i_told_you_so
    end
  end

  describe '#titleize' do
    it "returns titleized version of task name when no entity" do
      task = described_class.new(workflow_item)
      task.titleize.should == 'Go To Work'
    end

    it "returns titleized version of task name with entity" do
      task = described_class.new(workflow_item)
      task[:entity_id] = '45'
      task[:entity_type] = 'RhubarbSandwich'
      task.titleize.should == 'Go To Work: Rhubarb Sandwich 45'
    end

    it "returns titleized version of task name without entity if requested" do
      task = described_class.new(workflow_item)
      task[:entity_id] = '45'
      task[:entity_type] = 'RhubarbSandwich'
      task.titleize(:entity => false).should == 'Go To Work'
    end
  end
end
