describe Bumbleworks::ErrorLogger do
  subject {described_class.new(workitem)}
  let(:workitem) {double(:wf_name => 'armadillo', :error => 'something is amiss in dillo land', :wfid => 'zabme123', :fields => {})}

  it_behaves_like "an entity holder" do
    let(:holder) { described_class.new(workitem) }
    let(:storage_workitem) { Bumbleworks::Workitem.new(workitem) }
  end

  it 'calls registered logger and logs error information' do
    Bumbleworks.logger.should_receive(:error).with({
      :actor => 'armadillo',
      :action => 'process error',
      :target_type => nil,
      :target_id => nil,
      :metadata => {:wfid => 'zabme123', :error => 'something is amiss in dillo land'}
    })

    subject.on_error
  end

  it 'sets target to entity if found' do
    workitem.stub(:fields => {:entity_id => 1234, :entity_type => 'Lizards'})
    Bumbleworks.logger.should_receive(:error).with(hash_including({
      :target_type => 'Lizards',
      :target_id => 1234,
    }))

    subject.on_error
  end

  it 'does nothing if logger is not registered' do
    Bumbleworks.stub(:logger)
    subject.on_error.should == nil
  end
end
