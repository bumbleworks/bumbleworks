describe Bumbleworks::Worker::Proxy do
  subject {
    described_class.new(
      'class' => :f_class,
      'pid' => :f_pid,
      'name' => :f_name,
      'id' => :f_id,
      'state' => :f_state,
      'ip' => :f_ip,
      'hostname' => :f_hostname,
      'system' => :f_system,
      'launched_at' => '2010-10-10 10:10:10'
    )
  }

  describe "#launched_at" do
    let(:expected_time) { Time.parse('2010-10-10 10:10:10') }

    it "returns initialized launched_at string parsed as Time" do
      expect(subject.launched_at).to eq(expected_time)
    end

    it "returns launched_at directly if already Time" do
      subject.instance_variable_set(:@launched_at, expected_time)
      expect(subject.launched_at).to eq(expected_time)
    end
  end

  describe "#class_name" do
    it "returns class passed in from hash" do
      expect(subject.class_name).to eq("f_class")
    end
  end

  describe "#storage" do
    it "returns nil to allow default" do
      expect(subject.storage).to be_nil
    end
  end
end