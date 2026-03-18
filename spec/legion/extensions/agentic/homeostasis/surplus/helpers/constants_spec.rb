# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Surplus::Helpers::Constants do
  describe 'constants' do
    it 'defines TOTAL_CAPACITY as 1.0' do
      expect(described_class::TOTAL_CAPACITY).to eq(1.0)
    end

    it 'defines MIN_RESERVE as 0.1' do
      expect(described_class::MIN_RESERVE).to eq(0.1)
    end

    it 'defines SURPLUS_THRESHOLD as 0.15' do
      expect(described_class::SURPLUS_THRESHOLD).to eq(0.15)
    end

    it 'defines REPLENISH_RATE as 0.05' do
      expect(described_class::REPLENISH_RATE).to eq(0.05)
    end

    it 'defines DEPLETION_RATE as 0.08' do
      expect(described_class::DEPLETION_RATE).to eq(0.08)
    end

    it 'defines all ALLOCATION_TYPES' do
      expect(described_class::ALLOCATION_TYPES).to include(:exploration, :consolidation, :speculation, :maintenance, :creative)
    end
  end

  describe '.surplus_label' do
    it 'returns :abundant for high surplus' do
      expect(described_class.surplus_label(0.8)).to eq(:abundant)
    end

    it 'returns :moderate for moderate surplus' do
      expect(described_class.surplus_label(0.4)).to eq(:moderate)
    end

    it 'returns :scarce for scarce surplus' do
      expect(described_class.surplus_label(0.2)).to eq(:scarce)
    end

    it 'returns :depleted for very low surplus' do
      expect(described_class.surplus_label(0.05)).to eq(:depleted)
    end

    it 'returns :none for zero surplus' do
      expect(described_class.surplus_label(0.0)).to eq(:depleted)
    end
  end

  describe '.quality_label' do
    it 'returns :peak for high quality' do
      expect(described_class.quality_label(0.9)).to eq(:peak)
    end

    it 'returns :rested for good quality' do
      expect(described_class.quality_label(0.7)).to eq(:rested)
    end

    it 'returns :residual for moderate quality' do
      expect(described_class.quality_label(0.4)).to eq(:residual)
    end

    it 'returns :degraded for low quality' do
      expect(described_class.quality_label(0.1)).to eq(:degraded)
    end
  end

  describe '.valid_allocation_type?' do
    it 'returns true for valid types' do
      expect(described_class.valid_allocation_type?(:exploration)).to be true
      expect(described_class.valid_allocation_type?(:creative)).to be true
    end

    it 'returns false for invalid types' do
      expect(described_class.valid_allocation_type?(:unknown)).to be false
    end
  end

  describe '.clamp' do
    it 'clamps to [0.0, 1.0] by default' do
      expect(described_class.clamp(1.5)).to eq(1.0)
      expect(described_class.clamp(-0.5)).to eq(0.0)
      expect(described_class.clamp(0.5)).to eq(0.5)
    end
  end
end
