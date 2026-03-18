# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Metabolism::Helpers::Constants do
  describe 'MAX_ENERGY' do
    it 'equals 1000.0' do
      expect(described_class::MAX_ENERGY).to eq(1000.0)
    end
  end

  describe 'RESTING_METABOLIC_RATE' do
    it 'equals 0.5' do
      expect(described_class::RESTING_METABOLIC_RATE).to eq(0.5)
    end
  end

  describe 'RECOVERY_RATE' do
    it 'equals 2.0' do
      expect(described_class::RECOVERY_RATE).to eq(2.0)
    end
  end

  describe 'EFFICIENCY_DECAY' do
    it 'equals 0.01' do
      expect(described_class::EFFICIENCY_DECAY).to eq(0.01)
    end
  end

  describe 'OPERATION_COSTS' do
    it 'defines perception cost as 5.0' do
      expect(described_class::OPERATION_COSTS[:perception]).to eq(5.0)
    end

    it 'defines memory_retrieval cost as 8.0' do
      expect(described_class::OPERATION_COSTS[:memory_retrieval]).to eq(8.0)
    end

    it 'defines reasoning cost as 15.0' do
      expect(described_class::OPERATION_COSTS[:reasoning]).to eq(15.0)
    end

    it 'defines creativity cost as 20.0' do
      expect(described_class::OPERATION_COSTS[:creativity]).to eq(20.0)
    end

    it 'defines decision cost as 12.0' do
      expect(described_class::OPERATION_COSTS[:decision]).to eq(12.0)
    end

    it 'defines communication cost as 10.0' do
      expect(described_class::OPERATION_COSTS[:communication]).to eq(10.0)
    end

    it 'is frozen' do
      expect(described_class::OPERATION_COSTS).to be_frozen
    end
  end

  describe 'METABOLIC_STATES' do
    it 'contains all five states' do
      expect(described_class::METABOLIC_STATES).to contain_exactly(:optimal, :efficient, :normal, :strained, :depleted)
    end

    it 'is frozen' do
      expect(described_class::METABOLIC_STATES).to be_frozen
    end
  end

  describe '.label_for' do
    it 'returns :optimal for ratio >= 0.8' do
      expect(described_class.label_for(1.0)).to eq(:optimal)
      expect(described_class.label_for(0.85)).to eq(:optimal)
      expect(described_class.label_for(0.8)).to eq(:optimal)
    end

    it 'returns :efficient for ratio 0.6..0.8' do
      expect(described_class.label_for(0.7)).to eq(:efficient)
      expect(described_class.label_for(0.6)).to eq(:efficient)
    end

    it 'returns :normal for ratio 0.4..0.6' do
      expect(described_class.label_for(0.5)).to eq(:normal)
      expect(described_class.label_for(0.4)).to eq(:normal)
    end

    it 'returns :strained for ratio 0.15..0.4' do
      expect(described_class.label_for(0.25)).to eq(:strained)
      expect(described_class.label_for(0.15)).to eq(:strained)
    end

    it 'returns :depleted for ratio below 0.15' do
      expect(described_class.label_for(0.1)).to eq(:depleted)
      expect(described_class.label_for(0.0)).to eq(:depleted)
    end

    it 'clamps values above 1.0 to optimal' do
      expect(described_class.label_for(1.5)).to eq(:optimal)
    end

    it 'clamps values below 0.0 to depleted' do
      expect(described_class.label_for(-0.1)).to eq(:depleted)
    end
  end
end
