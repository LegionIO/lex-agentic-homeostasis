# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Pendulum::Helpers::Constants do
  describe 'POLE_PAIRS' do
    it 'defines five pole pairs' do
      expect(described_class::POLE_PAIRS.size).to eq(5)
    end

    it 'includes certainty_doubt' do
      expect(described_class::POLE_PAIRS[:certainty_doubt]).to eq(%i[certainty doubt])
    end

    it 'includes focus_diffusion' do
      expect(described_class::POLE_PAIRS[:focus_diffusion]).to eq(%i[focus diffusion])
    end

    it 'includes analysis_intuition' do
      expect(described_class::POLE_PAIRS[:analysis_intuition]).to eq(%i[analysis intuition])
    end

    it 'includes approach_avoidance' do
      expect(described_class::POLE_PAIRS[:approach_avoidance]).to eq(%i[approach avoidance])
    end

    it 'includes convergent_divergent' do
      expect(described_class::POLE_PAIRS[:convergent_divergent]).to eq(%i[convergent divergent])
    end

    it 'is frozen' do
      expect(described_class::POLE_PAIRS).to be_frozen
    end
  end

  describe 'DAMPING_RATE' do
    it 'is 0.01' do
      expect(described_class::DAMPING_RATE).to eq(0.01)
    end
  end

  describe 'MAX_PENDULUMS' do
    it 'is 100' do
      expect(described_class::MAX_PENDULUMS).to eq(100)
    end
  end

  describe 'AMPLITUDE_LABELS' do
    it 'has 5 ranges' do
      expect(described_class::AMPLITUDE_LABELS.size).to eq(5)
    end

    it 'is frozen' do
      expect(described_class::AMPLITUDE_LABELS).to be_frozen
    end
  end

  describe '.valid_pole_pair?' do
    it 'returns true for known pole pairs' do
      expect(described_class.valid_pole_pair?(:certainty_doubt)).to be true
    end

    it 'returns false for unknown pole pairs' do
      expect(described_class.valid_pole_pair?(:unknown)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid_pole_pair?(nil)).to be false
    end
  end

  describe '.amplitude_label' do
    it 'returns :minimal for 0.0' do
      expect(described_class.amplitude_label(0.0)).to eq(:minimal)
    end

    it 'returns :minimal for 0.1' do
      expect(described_class.amplitude_label(0.1)).to eq(:minimal)
    end

    it 'returns :low for 0.3' do
      expect(described_class.amplitude_label(0.3)).to eq(:low)
    end

    it 'returns :moderate for 0.5' do
      expect(described_class.amplitude_label(0.5)).to eq(:moderate)
    end

    it 'returns :high for 0.7' do
      expect(described_class.amplitude_label(0.7)).to eq(:high)
    end

    it 'returns :maximal for 1.0' do
      expect(described_class.amplitude_label(1.0)).to eq(:maximal)
    end

    it 'clamps values above 1.0' do
      expect(described_class.amplitude_label(1.5)).to eq(:maximal)
    end

    it 'clamps values below 0.0' do
      expect(described_class.amplitude_label(-0.5)).to eq(:minimal)
    end
  end
end
