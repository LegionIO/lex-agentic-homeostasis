# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::Oscillator do
  subject(:osc) { described_class.new(id: :visual_cortex, domain: :perception) }

  let(:constants) { Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::Constants }

  describe '#initialize' do
    it 'sets id and domain' do
      expect(osc.id).to eq(:visual_cortex)
      expect(osc.domain).to eq(:perception)
    end

    it 'starts with zero power in all bands' do
      constants::BANDS.each { |b| expect(osc.power(b)).to eq(0.0) }
    end

    it 'starts with random phases' do
      constants::BANDS.each do |b|
        expect(osc.phase(b)).to be_between(0, 2 * Math::PI)
      end
    end
  end

  describe '#activate' do
    it 'increases power in the specified band' do
      osc.activate(band: :gamma, amount: 0.5)
      expect(osc.power(:gamma)).to eq(0.5)
    end

    it 'clamps at 1.0' do
      osc.activate(band: :gamma, amount: 0.8)
      osc.activate(band: :gamma, amount: 0.5)
      expect(osc.power(:gamma)).to eq(1.0)
    end

    it 'ignores unknown bands' do
      osc.activate(band: :unknown, amount: 0.5)
      expect(osc.power(:unknown)).to eq(0.0)
    end
  end

  describe '#suppress' do
    it 'decreases power' do
      osc.activate(band: :alpha, amount: 0.5)
      osc.suppress(band: :alpha, amount: 0.3)
      expect(osc.power(:alpha)).to be_within(0.001).of(0.2)
    end

    it 'does not go below zero' do
      osc.suppress(band: :alpha, amount: 0.5)
      expect(osc.power(:alpha)).to eq(0.0)
    end
  end

  describe '#dominant_band' do
    it 'returns nil when all bands are silent' do
      expect(osc.dominant_band).to be_nil
    end

    it 'returns the strongest band' do
      osc.activate(band: :theta, amount: 0.3)
      osc.activate(band: :gamma, amount: 0.6)
      expect(osc.dominant_band).to eq(:gamma)
    end
  end

  describe '#dominant?' do
    it 'returns false when no band above threshold' do
      osc.activate(band: :alpha, amount: 0.2)
      expect(osc.dominant?).to be false
    end

    it 'returns true when a band exceeds threshold' do
      osc.activate(band: :beta, amount: constants::DOMINANT_THRESHOLD + 0.1)
      expect(osc.dominant?).to be true
    end
  end

  describe '#advance_phase' do
    it 'changes phase for active bands' do
      osc.activate(band: :gamma, amount: 0.5)
      before = osc.phase(:gamma)
      osc.advance_phase
      expect(osc.phase(:gamma)).not_to eq(before)
    end

    it 'does not advance silent bands' do
      before = osc.phase(:delta)
      osc.advance_phase
      expect(osc.phase(:delta)).to eq(before)
    end
  end

  describe '#synchrony_with' do
    it 'returns 1.0 for identical phases' do
      other = described_class.new(id: :other)
      # force same phase
      osc.instance_variable_get(:@phases)[:gamma] = 1.0
      other.instance_variable_get(:@phases)[:gamma] = 1.0
      expect(osc.synchrony_with(other, band: :gamma)).to eq(1.0)
    end

    it 'returns 0.0 for opposite phases' do
      other = described_class.new(id: :other)
      osc.instance_variable_get(:@phases)[:gamma] = 0.0
      other.instance_variable_get(:@phases)[:gamma] = Math::PI
      expect(osc.synchrony_with(other, band: :gamma)).to be_within(0.01).of(0.0)
    end
  end

  describe '#decay' do
    it 'reduces power' do
      osc.activate(band: :beta, amount: 0.5)
      before = osc.power(:beta)
      osc.decay
      expect(osc.power(:beta)).to be < before
    end

    it 'does not go below zero' do
      osc.activate(band: :beta, amount: 0.01)
      10.times { osc.decay }
      expect(osc.power(:beta)).to be >= 0.0
    end
  end

  describe '#power_label' do
    it 'returns :silent for zero power' do
      expect(osc.power_label(:gamma)).to eq(:silent)
    end

    it 'returns :dominant for high power' do
      osc.activate(band: :gamma, amount: 0.9)
      expect(osc.power_label(:gamma)).to eq(:dominant)
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = osc.to_h
      expect(h).to include(:id, :domain, :powers, :dominant_band, :dominant, :phases)
    end
  end
end
