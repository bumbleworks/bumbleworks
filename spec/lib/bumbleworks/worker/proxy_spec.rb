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
      'launched_at' => :f_launched_at
    )
  }

  describe "#launched_at" do
    it "returns initialized launched_at string parsed as Time" do
      allow(Time).to receive(:parse).with(:f_launched_at).and_return(:a_time)
      expect(subject.launched_at).to eq(:a_time)
    end
  end
end