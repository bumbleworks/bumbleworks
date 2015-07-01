describe Bumbleworks::Task do
  subject { described_class.new(workflow_item) }

  let(:workflow_item) {
    Ruote::Workitem.new({
      'fields' => {
        'params' => {'task' => 'go_to_work', 'claimant' => 'employee'},
        'dispatched_at' => 'some time ago'
      }
    })
  }

  before :each do
    Bumbleworks::Ruote.register_participants
    Bumbleworks.start_worker!
  end

  it_behaves_like "an entity holder" do
    let(:holder) { described_class.new(workflow_item) }
    let(:storage_workitem) { Bumbleworks::Workitem.new(workflow_item) }
  end

  it_behaves_like "comparable" do
    let(:other) { described_class.new(workflow_item) }
    before(:each) do
      allow(workflow_item).to receive(:sid).and_return('blah-123-blah')
    end
  end

  describe '#not_completable_error_message' do
    it 'defaults to generic message' do
      task = described_class.new(workflow_item)
      expect(task.not_completable_error_message).to eq(
        "This task is not currently completable."
      )
    end
  end

  describe '.autoload_all' do
    it 'autoloads all task modules in directory' do
      Bumbleworks.root = File.join(fixtures_path, 'apps', 'with_default_directories')
      expect(Object).to receive(:autoload).with(:MakeSomeHoneyTask,
        File.join(Bumbleworks.root, 'tasks', 'make_some_honey_task.rb'))
      expect(Object).to receive(:autoload).with(:TasteThatMolassesTask,
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

  describe '#dispatched_at' do
    it 'returns dispatched_at timestamp from workitem' do
      expect(subject.dispatched_at).to eq 'some time ago'
    end
  end

  describe '#completable?' do
    it 'defaults to true on base task' do
      expect(subject).to be_completable
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
      expect_any_instance_of(described_class).to receive(:extend_module)
      described_class.new(workflow_item)
    end
  end

  describe '#reload' do
    it 'reloads the workitem from the storage participant' do
      allow(subject).to receive(:sid).and_return(:the_sid)
      expect(Bumbleworks.dashboard.storage_participant).to receive(
        :[]).with(:the_sid).and_return(:amazing_workitem)
      subject.reload
      expect(subject.instance_variable_get(:@workitem)).to eq(:amazing_workitem)
    end
  end

  [:before, :after].each do |phase|
    describe "#call_#{phase}_hooks" do
      it "calls #{phase} hooks on task and all observers" do
        observer1, observer2 = double('observer1'), double('observer2')
        Bumbleworks.observers = [observer1, observer2]
        expect(subject).to receive(:"#{phase}_snoogle").with(:chachunga, :faloop)
        expect(observer1).to receive(:"#{phase}_snoogle").with(:chachunga, :faloop)
        expect(observer2).to receive(:"#{phase}_snoogle").with(:chachunga, :faloop)
        subject.send(:"call_#{phase}_hooks", :snoogle, :chachunga, :faloop)
      end
    end
  end

  describe "#log" do
    it "creates a log entry with information from the task" do
      allow(subject).to receive(:id).and_return(:the_id)
      expect(Bumbleworks.logger).to receive(:info).with({
        :actor => "employee",
        :action => :did_a_thing,
        :target_type => "Task",
        :target_id => :the_id,
        :metadata => {
          :extra_stuff => "nothing special",
          :current_fields => {
            "params" => { "task" => "go_to_work", "claimant" => "employee" },
            "dispatched_at" => "some time ago"
          }
        }
      })
      subject.log(:did_a_thing, :extra_stuff => "nothing special")
    end
  end

  describe '#on_dispatch' do
    it 'logs dispatch' do
      expect(subject).to receive(:log).with(:dispatch)
      subject.on_dispatch
    end

    it 'calls after hooks' do
      allow(subject).to receive(:log)
      expect(subject).to receive(:call_after_hooks).with(:dispatch)
      subject.on_dispatch
    end
  end

  describe '#extend_module' do
    it 'extends with base module and task module' do
      expect(subject).to receive(:task_module).and_return(:task_module_double)
      expect(subject).to receive(:extend).with(Bumbleworks::Task::Base).ordered
      expect(subject).to receive(:extend).with(:task_module_double).ordered
      subject.extend_module
    end

    it 'extends only with base module if no nickname' do
      allow(subject).to receive(:nickname).and_return(nil)
      expect(subject).to receive(:extend).with(Bumbleworks::Task::Base)
      subject.extend_module
    end

    it 'extends only with base module if task module does not exist' do
      expect(subject).to receive(:extend).with(Bumbleworks::Task::Base)
      subject.extend_module
    end
  end

  describe '#task_module' do
    it 'returns nil if no nickname' do
      allow(subject).to receive(:nickname).and_return(nil)
      expect(subject.task_module).to be_nil
    end

    it 'returns constantized task nickname with "Task" appended' do
      subject
      allow(Bumbleworks::Support).to receive(:constantize).with("GoToWorkTask").and_return(:the_task_module)
      expect(subject.task_module).to eq(:the_task_module)
    end
  end

  describe '#id' do
    it 'returns the sid from the workitem' do
      allow(workflow_item).to receive(:sid).and_return(:an_exciting_id)
      expect(subject.id).to eq(:an_exciting_id)
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
      expect(described_class.find_by_id(plant_noodle_seed_task.id).sid).to eq(
        plant_noodle_seed_task.sid
      )
      expect(described_class.find_by_id(give_the_horse_a_bon_bon_task.id).sid).to eq(
        give_the_horse_a_bon_bon_task.sid
      )
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

  context 'ordering' do
    before :each do
      Bumbleworks.define_process 'emergency_hamster_bullet' do
        concurrence do
          doctor :task => 'evince_concern', :priority => 3, :importance => 1000
          patient :task => 'panic', :priority => 2, :importance => 5
          nurse :task => 'roll_eyes', :priority => 4, :importance => 1000
          officer :task => 'appear_authoritative', :priority => 1, :importance => 1000
          rhubarb :task => 'sit_quietly', :importance => 80
        end
      end
    end

    context 'by params' do
      before(:each) do
        Bumbleworks.launch!('emergency_hamster_bullet')
        Bumbleworks.dashboard.wait_for(:rhubarb)
      end

      describe '.order_by_param' do
        it 'orders returned tasks by given param ascending by default' do
          tasks = described_class.order_by_param(:priority)
          expect(tasks.map(&:nickname)).to eq([
            'appear_authoritative',
            'panic',
            'evince_concern',
            'roll_eyes',
            'sit_quietly'
          ])
        end

        it 'can order in reverse' do
          tasks = described_class.order_by_param(:priority, :desc)
          expect(tasks.map(&:nickname)).to eq([
            'sit_quietly',
            'roll_eyes',
            'evince_concern',
            'panic',
            'appear_authoritative'
          ])
        end
      end

      describe '.order_by_params' do
        it 'orders by multiple parameters' do
          tasks = described_class.order_by_params(:importance => :desc, :priority => :asc)
          expect(tasks.map(&:nickname)).to eq([
            'appear_authoritative',
            'evince_concern',
            'roll_eyes',
            'sit_quietly',
            'panic'
          ])
        end
      end
    end

    context 'by fields' do
      before(:each) do
        @wf3 = Bumbleworks.launch!('emergency_hamster_bullet', :group => 2, :strength => 3)
        Bumbleworks.dashboard.wait_for(:officer)
        @wf1 = Bumbleworks.launch!('emergency_hamster_bullet', :group => 2, :strength => 1)
        Bumbleworks.dashboard.wait_for(:officer)
        @wf2 = Bumbleworks.launch!('emergency_hamster_bullet', :group => 1, :strength => 2)
        Bumbleworks.dashboard.wait_for(:officer)
        @wf4 = Bumbleworks.launch!('emergency_hamster_bullet', :group => 1, :strength => 4)
        Bumbleworks.dashboard.wait_for(:officer)
        @wf5 = Bumbleworks.launch!('emergency_hamster_bullet', :group => 1)
        Bumbleworks.dashboard.wait_for(:officer)
      end

      describe '.order_by_field' do
        it 'orders returned tasks by given param ascending by default' do
          tasks = described_class.for_role('doctor').order_by_field(:strength)
          expect(tasks.map { |t| [t.nickname, t.wfid] }).to eq([
            ['evince_concern', @wf1.wfid],
            ['evince_concern', @wf2.wfid],
            ['evince_concern', @wf3.wfid],
            ['evince_concern', @wf4.wfid],
            ['evince_concern', @wf5.wfid]
          ])
        end

        it 'can order in reverse' do
          tasks = described_class.for_role('doctor').order_by_field(:strength, :desc)
          expect(tasks.map { |t| [t.nickname, t.wfid] }).to eq([
            ['evince_concern', @wf5.wfid],
            ['evince_concern', @wf4.wfid],
            ['evince_concern', @wf3.wfid],
            ['evince_concern', @wf2.wfid],
            ['evince_concern', @wf1.wfid]
          ])
        end
      end

      describe '.order_by_fields' do
        it 'orders by multiple parameters' do
          tasks = described_class.for_role('doctor').order_by_fields(:group => :asc, :strength => :desc)
          expect(tasks.map { |t| [t.nickname, t.wfid] }).to eq([
            ['evince_concern', @wf5.wfid],
            ['evince_concern', @wf4.wfid],
            ['evince_concern', @wf2.wfid],
            ['evince_concern', @wf3.wfid],
            ['evince_concern', @wf1.wfid]
          ])
        end
      end
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
      expect(tasks.map(&:nickname)).to eq([
        'comment_on_dancing_ability',
        'ignore_pleas_for_attention'
      ])
    end

    it 'works with symbolized role names' do
      Bumbleworks.dashboard.wait_for(:father)
      tasks = described_class.for_roles([:heckler, :mother])
      expect(tasks.map(&:nickname)).to eq([
        'comment_on_dancing_ability',
        'ignore_pleas_for_attention'
      ])
    end

    it 'returns empty array if no tasks found for given roles' do
      Bumbleworks.dashboard.wait_for(:father)
      expect(described_class.for_roles(['elephant'])).to be_empty
    end

    it 'returns empty array if given empty array' do
      Bumbleworks.dashboard.wait_for(:father)
      expect(described_class.for_roles([])).to be_empty
    end

    it 'returns empty array if given nil' do
      Bumbleworks.dashboard.wait_for(:father)
      expect(described_class.for_roles(nil)).to be_empty
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

      expect(spunking_tasks.map(&:nickname)).to match_array(['spunk', 'complain'])
      expect(rooting_tasks.map(&:nickname)).to match_array(['get_the_rooting_on', 'scoff'])
      expect(tasks_for_both.map(&:nickname)).to match_array(['spunk', 'complain', 'get_the_rooting_on', 'scoff'])
    end

    it 'works with process ids as well' do
      spunking_tasks = described_class.for_processes([@spunking_process.id])
      expect(spunking_tasks.map(&:nickname)).to match_array(['spunk', 'complain'])
    end

    it 'returns empty array when no tasks for given process id' do
      expect(described_class.for_processes(['boop'])).to be_empty
    end

    it 'returns empty array if given empty array' do
      expect(described_class.for_processes([])).to be_empty
    end

    it 'returns empty array if given nil' do
      expect(described_class.for_processes(nil)).to be_empty
    end
  end

  describe '.for_process' do
    it 'acts as shortcut to .for_processes with one process' do
      allow_any_instance_of(described_class::Finder).to receive(:for_processes).with([:one_guy]).and_return(:aha)
      expect(described_class.for_process(:one_guy)).to eq(:aha)
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
      expect(tasks.map(&:nickname)).to eq([
        'make_chalk_drawings',
        'chalk_it_good_baby'
      ])
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
      expect(@unclaimed.map(&:nickname)).to match_array(['eat', 'bark', 'pet_dog', 'skip_and_jump'])
      described_class.all.each do |t|
        t.claim('radish') unless ['pet_dog', 'bark'].include?(t.nickname)
      end
      @unclaimed = described_class.unclaimed
      expect(@unclaimed.map(&:nickname)).to match_array(['pet_dog', 'bark'])
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
      expect(described_class.claimed).to be_empty
      described_class.all.each_with_index do |t, i|
        t.claim("radish_#{i}") unless ['pet_dog', 'bark'].include?(t.nickname)
      end
      @claimed = described_class.claimed
      expect(@claimed.map(&:nickname)).to match_array(['eat', 'skip_and_jump'])
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
      expect(tasks.map { |t| [t.role, t.nickname] }).to eq([
        ['a_fella', 'waggle_hands'],
        ['a_lady', 'wiggle_hands']
      ])
      tasks = described_class.completable(false)
      expect(tasks.map { |t| [t.role, t.nickname] }).to eq([
        ['a_monkey', 'wuggle_hands']
      ])
    end
  end

  context 'iterators' do
    before :each do
      Bumbleworks.define_process 'life_on_tha_street' do
        concurrence do
          oscar :task => 'grouch_it_up'
          elmo :task => 'sing_a_tune'
          elmo :task => 'steal_booze'
          snuffy :task => 'eat_cabbage'
        end
      end
      Bumbleworks.launch!('life_on_tha_street')
      Bumbleworks.dashboard.wait_for(:snuffy)
    end

    describe '.each' do
      it 'executes for each found task' do
        list = []
        described_class.each { |t| list << t.nickname }
        expect(list).to match_array(['grouch_it_up', 'sing_a_tune', 'steal_booze', 'eat_cabbage'])
      end
    end

    describe '.map' do
      it 'maps result of yielding block with each task' do
        list = described_class.map { |t| t.nickname }
        expect(list).to match_array(['grouch_it_up', 'sing_a_tune', 'steal_booze', 'eat_cabbage'])
      end
    end

    context 'with queries' do
      it 'checks filters' do
        list = described_class.for_role('elmo').map { |t| t.nickname }
        expect(list).to match_array(['sing_a_tune', 'steal_booze'])
      end
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
      expect(tasks.map { |t| [t.role, t.nickname] }).to eq([
        ['dog_teeth', 'eat'],
        ['dog_mouth', 'bark'],
        ['everyone', 'pet_dog'],
        ['dog_legs', 'skip_and_jump']
      ])
    end

    it 'uses subclass for generation of tasks' do
      class MyOwnTask < Bumbleworks::Task; end
      Bumbleworks.dashboard.wait_for(:dog_legs)
      tasks = MyOwnTask.all
      expect(tasks).to be_all { |t| t.class == MyOwnTask }
      Object.send(:remove_const, :MyOwnTask)
    end
  end

  describe '#[], #[]=' do
    it 'sets values on workitem fields' do
      subject['hive'] = 'bees at work'
      expect(workflow_item.fields['hive']).to eq('bees at work')
    end

    it 'retuns value from workitem params' do
      workflow_item.fields['nest'] = 'queen resting'
      expect(subject['nest']).to eq('queen resting')
    end
  end

  describe '#nickname' do
    it 'returns the "task" param' do
      expect(subject.nickname).to eq('go_to_work')
    end

    it 'is immutable; cannot be changed by modifying the param' do
      expect(subject.nickname).to eq('go_to_work')
      subject.params['task'] = 'what_is_wrong_with_you?'
      expect(subject.nickname).to eq('go_to_work')
    end
  end

  describe '#role' do
    it 'returns the workitem participant_name' do
      Bumbleworks.define_process 'planting_a_noodle' do
        noodle_gardener :task => 'plant_noodle_seed'
      end
      Bumbleworks.launch!('planting_a_noodle')
      Bumbleworks.dashboard.wait_for(:noodle_gardener)
      expect(described_class.all.first.role).to eq('noodle_gardener')
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
      expect(described_class.for_claimant('radish')).to be_empty
      described_class.all.each do |t|
        t.claim('radish') unless t.nickname == 'pet_dog'
      end
      @tasks = described_class.for_claimant('radish')
      expect(@tasks.map(&:nickname)).to match_array(['eat', 'bark', 'skip_and_jump'])
    end
  end

  describe '.with_fields' do
    before(:each) do
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
    end

    it 'returns all tasks with given field' do
      expect(described_class.with_fields(:grumbles => true).count).to eq(3)
      expect(described_class.with_fields(:bumby => 'fancy').count).to eq(1)
      expect(described_class.with_fields(:bumby => 'not_fancy').count).to eq(2)
      expect(described_class.with_fields(:what => 'ever')).to be_empty
    end

    it 'looks up multiple fields at once' do
      expect(described_class.with_fields(:grumbles => true, :bumby => 'not_fancy').count).to eq(2)
      expect(described_class.with_fields(:grumbles => false, :bumby => 'not_fancy')).to be_empty
    end

    it 'can be chained' do
      expect(described_class.with_fields(:grumbles => true).with_fields(:bumby => 'fancy').count).to eq(1)
      expect(described_class.with_fields(:grumbles => false).with_fields(:bumby => 'not_fancy')).to be_empty
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
      expect(tasks.size).to eq(2)
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
      expect(tasks.map(&:role)).to match_array(['goose', 'rabbit'])
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
        expect(@task.params['claimant']).to eq('boss')
      end

      it 'sets claimed_at param' do
        expect(@task.params['claimed_at']).not_to be_nil
      end

      it 'raises an error if already claimed by someone else' do
        expect{@task.claim('peon')}.to raise_error described_class::AlreadyClaimed
      end

      it 'does not raise an error if attempting to claim by same token' do
        expect{@task.claim('boss')}.not_to raise_error
      end

      it 'calls before_claim and after_claim callbacks' do
        allow(subject).to receive(:log)
        expect(subject).to receive(:before_claim).with(:doctor_claim).ordered
        expect(subject).to receive(:set_claimant).ordered
        expect(subject).to receive(:after_claim).with(:doctor_claim).ordered
        subject.claim(:doctor_claim)
      end

      it 'skips callbacks if requested' do
        allow(subject).to receive(:log)
        expect(subject).to receive(:before_claim).never
        expect(subject).to receive(:set_claimant)
        expect(subject).to receive(:after_claim).never
        subject.claim(:doctor_claim, :skip_callbacks => true)
      end

      it 'logs event' do
        @task.release
        expect(@task).to receive(:log).with(:claim)
        @task.claim(:whatever)
      end
    end

    describe '#claimant' do
      it 'returns token of who has claim' do
        expect(@task.claimant).to eq('boss')
      end
    end

    describe '#claimed_at' do
      it 'returns claimed_at param' do
        expect(@task.claimed_at).to eq(@task.params['claimed_at'])
      end
    end

    describe '#claimed?' do
      it 'returns true if claimed' do
        expect(@task.claimed?).to be_truthy
      end

      it 'false otherwise' do
        @task.params['claimant'] = nil
        expect(@task.claimed?).to be_falsy
      end
    end

    describe '#release' do
      it "release claim on workitem" do
        expect(@task).to be_claimed
        @task.release
        expect(@task).not_to be_claimed
      end

      it 'clears claimed_at param' do
        @task.release
        expect(@task.params['claimed_at']).to be_nil
      end

      it 'calls with hooks' do
        expect(@task).to receive(:call_before_hooks).with(:release, 'boss').ordered
        expect(@task).to receive(:set_claimant).ordered
        expect(@task).to receive(:call_after_hooks).with(:release, 'boss').ordered
        @task.release
      end

      it 'skips callbacks if requested' do
        expect(@task).to receive(:call_before_hooks).never
        expect(@task).to receive(:set_claimant)
        expect(@task).to receive(:call_after_hooks).never
        @task.release(:skip_callbacks => true)
      end

      it 'logs event' do
        expect(@task).to receive(:log).with(:release)
        @task.release
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
        expect(task.params['state']).to eq('is ready')
        expect(task.fields['meal']).to eq('salted_rhubarb')
      end

      it 'calls with hooks' do
        allow(subject).to receive(:log)
        expect(subject).to receive(:call_before_hooks).with(:update, :argue_mints).ordered
        expect(subject).to receive(:update_workitem).ordered
        expect(subject).to receive(:call_after_hooks).with(:update, :argue_mints).ordered
        subject.update(:argue_mints)
      end

      it 'skips callbacks if requested' do
        allow(subject).to receive(:log)
        expect(subject).to receive(:call_before_hooks).never
        expect(subject).to receive(:update_workitem)
        expect(subject).to receive(:call_after_hooks).never
        subject.update({:actual => :params}, {:skip_callbacks => true})
      end

      it 'reloads after updating workitem' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        allow(task).to receive(:log)
        expect(described_class.storage_participant).to receive(:update).with(task.workitem).ordered
        expect(task).to receive(:reload).ordered
        task.update(:noofles)
      end

      it 'logs event' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['claimant'] = :some_user
        expect(task).to receive(:log).with(:update, :extra_data => :fancy)
        task.update(:extra_data => :fancy)
      end
    end

    describe '#complete' do
      it 'saves fields and proceeds to next expression' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['state'] = 'is ready'
        task.fields['meal'] = 'root beer and a kite'
        task.complete
        expect(described_class.for_role('dog_mouth')).to be_empty
        event = Bumbleworks.dashboard.wait_for :dog_brain
        task = described_class.for_role('dog_brain').first
        expect(task.params['state']).to be_nil
        expect(task.fields['meal']).to eq('root beer and a kite')
      end

      it 'throws exception if task is not completable' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        allow(task).to receive(:completable?).and_return(false)
        allow(task).to receive(:not_completable_error_message).and_return('hogwash!')
        expect(task).to receive(:before_update).never
        expect(task).to receive(:before_complete).never
        expect(task).to receive(:proceed_workitem).never
        expect(task).to receive(:after_complete).never
        expect(task).to receive(:after_update).never
        expect {
          task.complete
        }.to raise_error(Bumbleworks::Task::NotCompletable, "hogwash!")
        expect(described_class.for_role('dog_mouth')).not_to be_empty
      end

      it 'calls update and complete callbacks' do
        allow(subject).to receive(:log)
        expect(subject).to receive(:call_before_hooks).with(:update, :argue_mints).ordered
        expect(subject).to receive(:call_before_hooks).with(:complete, :argue_mints).ordered
        expect(subject).to receive(:proceed_workitem).ordered
        expect(subject).to receive(:call_after_hooks).with(:complete, :argue_mints).ordered
        expect(subject).to receive(:call_after_hooks).with(:update, :argue_mints).ordered
        subject.complete(:argue_mints)
      end

      it 'skips callbacks if requested' do
        allow(subject).to receive(:log)
        expect(subject).to receive(:call_before_hooks).never
        expect(subject).to receive(:proceed_workitem)
        expect(subject).to receive(:call_after_hooks).never
        subject.complete({:actual => :params}, {:skip_callbacks => true})
      end

      it 'logs event' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['claimant'] = :some_user
        expect(task).to receive(:log).with(:complete, :extra_data => :fancy)
        task.complete(:extra_data => :fancy)
      end
    end
  end

  describe 'chained queries' do
    before(:each) do
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
    end

    it 'allows for AND-ed chained finders' do
      tasks = described_class.
        for_roles(['green', 'pink']).
        by_nickname('be_proud')
      expect(tasks.map(&:nickname)).to match_array(['be_proud', 'be_proud'])

      tasks = described_class.
        for_roles(['green', 'pink', 'blue']).
        completable.
        by_nickname('be_proud')
      expect(tasks.map(&:nickname)).to match_array(['be_proud'])
      expect(tasks.first.role).to eq('pink')

      tasks = described_class.
        for_claimant('crayon_box').
        for_roles(['red', 'yellow', 'green'])
      expect(tasks.map(&:nickname)).to match_array(['be_really_mad', 'be_scared'])

      tasks = described_class.
        for_claimant('crayon_box').
        by_nickname('be_a_bit_sad').
        for_role('blue')
      expect(tasks.map(&:nickname)).to eq(['be_a_bit_sad'])
    end

    it 'allows for OR-ed chained finders' do
      tasks = described_class.where_any.
        for_role('blue').
        by_nickname('be_proud')
      expect(tasks.map(&:nickname)).to match_array(['be_a_bit_sad', 'be_proud', 'be_proud'])

      tasks = described_class.where_any.
        completable.
        claimed
      expect(tasks.map(&:nickname)).to match_array(['be_really_mad', 'be_scared', 'be_a_bit_sad', 'be_envious', 'be_proud'])
    end

    it 'allows for combination of AND-ed and OR-ed finders' do
      tasks = described_class.
        for_claimant('crayon_box').
        for_roles(['red', 'yellow', 'green']).
        where_any(:nickname => 'spittle', :role => 'red')
      expect(tasks.map(&:nickname)).to match_array(['be_really_mad'])
    end
  end

  describe 'method missing' do
    it 'calls method on new Finder object' do
      allow_any_instance_of(described_class::Finder).to receive(:shabam!).with(:yay).and_return(:its_a_me)
      expect(described_class.shabam!(:yay)).to eq(:its_a_me)
    end

    it 'falls back to method missing if no finder method' do
      expect {
        described_class.kerplunk!(:oh_no)
      }.to raise_error(NoMethodError)
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
      expect(task.nickname).to eq('finally_get_a_round_tuit')
      expect(end_time - start_time).to be >= 2
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
      expect(subject.humanize).to eq('Go to work')
    end

    it "returns humanized version of task name with entity" do
      subject[:entity_id] = '45'
      subject[:entity_type] = 'RhubarbSandwich'
      expect(subject.humanize).to eq('Go to work: Rhubarb sandwich 45')
    end

    it "returns humanized version of task name without entity if requested" do
      subject[:entity_id] = '45'
      subject[:entity_type] = 'RhubarbSandwich'
      expect(subject.humanize(:entity => false)).to eq('Go to work')
    end
  end

  describe '#to_s' do
    it "is aliased to #titleize" do
      allow(subject).to receive(:titleize).with(:the_args).and_return(:see_i_told_you_so)
      expect(subject.to_s(:the_args)).to eq(:see_i_told_you_so)
    end
  end

  describe '#titleize' do
    it "returns titleized version of task name when no entity" do
      expect(subject.titleize).to eq('Go To Work')
    end

    it "returns titleized version of task name with entity" do
      subject[:entity_id] = '45'
      subject[:entity_type] = 'RhubarbSandwich'
      expect(subject.titleize).to eq('Go To Work: Rhubarb Sandwich 45')
    end

    it "returns titleized version of task name without entity if requested" do
      subject[:entity_id] = '45'
      subject[:entity_type] = 'RhubarbSandwich'
      expect(subject.titleize(:entity => false)).to eq('Go To Work')
    end
  end

  describe '#temporary_storage' do
    it 'returns an empty hash by default' do
      expect(subject.temporary_storage).to eq({})
    end

    it 'persists stored values' do
      subject.temporary_storage[:foo] = :bar
      expect(subject.temporary_storage[:foo]).to eq(:bar)
    end
  end

  it 'has a CompletionFailed error class' do
    expect(described_class::CompletionFailed.new).to be_a(StandardError)
  end
end
