require 'spec_helper'

describe Bumbleworks::Task do
  let(:workflow_item) {Ruote::Workitem.new('fields' => {'params' => {'task' => 'go_to_work'} })}

  before :each do
    Bumbleworks.reset!
    Bumbleworks.storage = {}

    Bumbleworks.register_participants do
      catchall
    end

    Bumbleworks.register_participant_list
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

  describe '.for_role' do
    it 'delegates to #for_roles with single-item array' do
      described_class.should_receive(:for_roles).with(['mister_mystery'])
      described_class.for_role('mister_mystery')
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

  context 'claiming things' do
    subject{described_class.new(workflow_item)}
    before :each do
      subject.stub(:save)
      workflow_item.params['claimant'] = nil
      subject.claim('boss')
    end

    describe '#claim' do
      it 'sets token on  "claimant" param' do
        workflow_item.params['claimant'].should == 'boss'
      end

      it 'raises an error if already claimed by someone else' do
        expect{subject.claim('peon')}.to raise_error Bumbleworks::ClaimError
      end

      it 'does not raise an error if attempting to claim by same token' do
        expect{subject.claim('boss')}.not_to raise_error Bumbleworks::ClaimError
      end
    end

    describe '#claimant' do
      it 'returns token of who has claim' do
        subject.claimant.should == 'boss'
      end
    end

    describe '#claimed?' do
      it 'returns true if claimed' do
        subject.claimed?.should be_true
      end

      it 'false otherwise' do
        workflow_item.params['claimant'] = nil
        subject.claimed?.should be_false
      end
    end

    describe '#release' do
      it "release claim on workitem" do
        subject.should be_claimed
        subject.release
        subject.should_not be_claimed
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

    describe '#save' do
      it 'saves fields and params, but does not proceed process' do
        event = Bumbleworks.dashboard.wait_for :dog_mouth
        task = described_class.for_role('dog_mouth').first
        task.params['state'] = 'is ready'
        task.fields['meal'] = 'salted_rhubarb'
        task.save
        task = described_class.for_role('dog_mouth').first
        task.params['state'].should == 'is ready'
        task.fields['meal'].should == 'salted_rhubarb'
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
    end
  end
end
