require 'spec_helper'

describe Bumbleworks::Task do
  let(:workflow_item) {Ruote::Workitem.new('fields' => {'params' => {'task' => 'go_to_work'} })}
  let(:unnamed_workflow_item) {Ruote::Workitem.new('fields' => {'params' => {} })}

  before :each do
    Bumbleworks.reset!
    Bumbleworks.storage = {}

    Bumbleworks.register_participants do
      catchall
    end

    Bumbleworks.register_participant_list
  end

  describe '.for_actor' do
    before :each do
      Bumbleworks.define_process 'cat-lifecycle' do
        concurrence do
          human :task => 'pet'
          cat :task => 'purr'
        end
        human :task => 'feed'
        cat :task => 'eat'
        cat :task => 'nap'
      end
      Bumbleworks.launch!('cat-lifecycle')
    end

    it 'returns tasks waiting to be handled by actor' do
      Bumbleworks.dashboard.wait_for(:cat)

      tasks = described_class.for_actor('human')
      tasks.should have(1).items
      tasks.first.nickname.should == 'pet'
      tasks.first.wf_name.should == 'cat-lifecycle'

      tasks = described_class.for_actor('cat')
      tasks.should have(1).items
      tasks.first.nickname.should == 'purr'
      tasks.first.wf_name.should == 'cat-lifecycle'
    end

    it 'returns empty array if none found' do
      Bumbleworks.dashboard.wait_for(:cat, :timeout => 10)
      described_class.for_actor('bob').should == []
    end
  end

  describe '.all' do
    before :each do
      Bumbleworks.define_process 'dog-lifecycle' do
        concurrence do
          eat
          bark
          skip_and_jump
        end
        nap
      end
      Bumbleworks.launch!('dog-lifecycle')
    end

    it 'returns all tasks waiting for anyone to do them in the queue' do
      Bumbleworks.dashboard.wait_for(:skip_and_jump)
      described_class.all.map(&:actor).should == %w(eat bark skip_and_jump)
    end
  end

  describe '#[], #[]=' do
    subject{described_class.new(workflow_item)}
    it 'sets values on workitem params' do
      subject['hive'] = 'bees at work'
      workflow_item.params['hive'].should == 'bees at work'
    end

    it 'retuns value from workitem params' do
      workflow_item.params['nest'] = 'queen resting'
      subject['nest'].should == 'queen resting'
    end
  end

  describe '#nickname' do
    it 'uses the "task" param as the nickname of the task' do
      described_class.new(workflow_item).nickname.should == 'go_to_work'
    end

    it 'returns "unspecified" if process definition doesn\'t specify :task => "name"' do
      described_class.new(unnamed_workflow_item).nickname.should == 'unspecified'
    end
  end

  describe '#actor' do
    it 'returns the workitem participant_name' do
      Bumbleworks.define_process 'planting_a_noodle' do
        noodle_gardener :task => 'plant_noodle_seed'
      end
      Bumbleworks.launch!('planting_a_noodle')
      Bumbleworks.dashboard.wait_for(:noodle_gardener)
      described_class.all.first.actor.should == 'noodle_gardener'
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
        subject.claimed?.should be_true
        subject.release
        subject.claimed?.should be_false
      end
    end
  end

  context 'updating workflow engine' do
    before :each do
      Bumbleworks.define_process 'dog-lifecycle' do
        eat :dinner => 'still cooking'
        nap :task => 'cat_nap', :by => 'midnight'
      end
      Bumbleworks.launch!('dog-lifecycle')
    end

    describe '#save' do
      it 'updates storage participant' do
        event = Bumbleworks.dashboard.wait_for :eat
        task = described_class.for_actor('eat').first
        task['dinner'] = 'is ready'
        task.save
        wi = Bumbleworks.dashboard.storage_participant.by_wfid(task.id).first
        wi.params['dinner'].should == 'is ready'
      end
    end

    describe '#complete' do
      it 'releases the participant and allows engine to proceed to next item in the process' do
        event = Bumbleworks.dashboard.wait_for :eat
        task = described_class.for_actor('eat').first
        task.complete
        event = Bumbleworks.dashboard.wait_for :nap
        event['participant_name'].should == 'nap'
      end
    end
  end
end
