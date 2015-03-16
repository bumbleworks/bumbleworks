shared_examples "comparable" do
  describe "#hash" do
    it 'returns hash of identifier_for_comparison' do
      expect(subject.hash).to eq(subject.identifier_for_comparison.hash)
    end
  end

  describe '#==' do
    it 'returns true if identifier_for_comparison values are equal' do
      allow(other).to receive(:identifier_for_comparison).
        and_return(subject.identifier_for_comparison)
      expect(subject).to be == other
    end

    it 'returns false if other is different class' do
      different_classed_instance = double('whatever', :identifier_for_comparison => subject.identifier_for_comparison)
      expect(subject).not_to be == different_classed_instance
    end

    it 'returns false if identifier_for_comparison is nil' do
      allow(other).to receive(:identifier_for_comparison).and_return(nil)
      allow(subject).to receive(:identifier_for_comparison).and_return(nil)
      expect(subject).not_to be == other
    end
  end

  describe '#eql?' do
    it 'aliases to ==' do
      expect(subject).to receive(:==).with(other)
      subject.eql?(other)
    end
  end
end
