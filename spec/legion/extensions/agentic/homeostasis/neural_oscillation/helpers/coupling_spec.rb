# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::Coupling do
  subject(:coupling) { described_class.new(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma) }

  let(:constants) { Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::Constants }

  describe '#initialize' do
    it 'sets oscillator ids and band' do
      expect(coupling.oscillator_a).to eq(:visual)
      expect(coupling.oscillator_b).to eq(:auditory)
      expect(coupling.band).to eq(:gamma)
    end

    it 'uses default coupling strength' do
      expect(coupling.strength).to eq(constants::COUPLING_BOOST)
    end
  end

  describe '#key' do
    it 'returns sorted pair + band' do
      expect(coupling.key).to eq(%i[auditory visual gamma])
    end
  end

  describe '#strengthen' do
    it 'increases strength' do
      before = coupling.strength
      coupling.strengthen
      expect(coupling.strength).to be > before
    end

    it 'clamps at 1.0' do
      20.times { coupling.strengthen }
      expect(coupling.strength).to be <= 1.0
    end
  end

  describe '#decay' do
    it 'reduces strength' do
      coupling.strengthen(0.5)
      before = coupling.strength
      coupling.decay
      expect(coupling.strength).to be < before
    end
  end

  describe '#weak?' do
    it 'returns false initially' do
      expect(coupling.weak?).to be false
    end

    it 'returns true at floor' do
      coupling.strength = constants::COUPLING_FLOOR
      expect(coupling.weak?).to be true
    end
  end

  describe '#synchronized?' do
    it 'returns false with default strength' do
      expect(coupling.synchronized?).to be false
    end

    it 'returns true above sync threshold' do
      coupling.strength = constants::SYNC_THRESHOLD + 0.1
      expect(coupling.synchronized?).to be true
    end
  end

  describe '#involves?' do
    it 'returns true for either oscillator' do
      expect(coupling.involves?(:visual)).to be true
      expect(coupling.involves?(:auditory)).to be true
    end

    it 'returns false for unrelated oscillator' do
      expect(coupling.involves?(:motor)).to be false
    end
  end

  describe '#partner_of' do
    it 'returns the other oscillator' do
      expect(coupling.partner_of(:visual)).to eq(:auditory)
      expect(coupling.partner_of(:auditory)).to eq(:visual)
    end

    it 'returns nil for unrelated id' do
      expect(coupling.partner_of(:motor)).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = coupling.to_h
      expect(h).to include(:oscillator_a, :oscillator_b, :band, :strength, :synchronized)
    end
  end
end
