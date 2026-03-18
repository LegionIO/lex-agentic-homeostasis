# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::Constants do
  described_class = Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::Constants

  describe 'FUEL_TYPES' do
    it 'contains expected types' do
      expect(described_class::FUEL_TYPES).to eq(%i[coal oil gas peat shale])
    end

    it 'is frozen' do
      expect(described_class::FUEL_TYPES).to be_frozen
    end
  end

  describe 'GRADES' do
    it 'contains expected grades' do
      expect(described_class::GRADES).to eq(%i[crude refined premium synthetic])
    end

    it 'is frozen' do
      expect(described_class::GRADES).to be_frozen
    end
  end

  describe 'numeric constants' do
    it 'defines MAX_RESERVES' do
      expect(described_class::MAX_RESERVES).to eq(200)
    end

    it 'defines EXTRACTION_RATE' do
      expect(described_class::EXTRACTION_RATE).to eq(0.05)
    end

    it 'defines COMBUSTION_EFFICIENCY' do
      expect(described_class::COMBUSTION_EFFICIENCY).to eq(0.7)
    end

    it 'defines DEPLETION_WARNING' do
      expect(described_class::DEPLETION_WARNING).to eq(0.2)
    end
  end

  describe '.label_for' do
    context 'with RESERVE_LABELS' do
      it 'returns :abundant for high values' do
        expect(described_class.label_for(described_class::RESERVE_LABELS, 0.9)).to eq(:abundant)
      end

      it 'returns :healthy for 0.7' do
        expect(described_class.label_for(described_class::RESERVE_LABELS, 0.7)).to eq(:healthy)
      end

      it 'returns :moderate for 0.5' do
        expect(described_class.label_for(described_class::RESERVE_LABELS, 0.5)).to eq(:moderate)
      end

      it 'returns :scarce for 0.3' do
        expect(described_class.label_for(described_class::RESERVE_LABELS, 0.3)).to eq(:scarce)
      end

      it 'returns :critical for 0.1' do
        expect(described_class.label_for(described_class::RESERVE_LABELS, 0.1)).to eq(:critical)
      end
    end

    context 'with ENERGY_LABELS' do
      it 'returns :explosive for high values' do
        expect(described_class.label_for(described_class::ENERGY_LABELS, 0.85)).to eq(:explosive)
      end

      it 'returns :powerful for 0.7' do
        expect(described_class.label_for(described_class::ENERGY_LABELS, 0.7)).to eq(:powerful)
      end

      it 'returns :steady for 0.5' do
        expect(described_class.label_for(described_class::ENERGY_LABELS, 0.5)).to eq(:steady)
      end

      it 'returns :weak for 0.25' do
        expect(described_class.label_for(described_class::ENERGY_LABELS, 0.25)).to eq(:weak)
      end

      it 'returns :exhausted for 0.1' do
        expect(described_class.label_for(described_class::ENERGY_LABELS, 0.1)).to eq(:exhausted)
      end
    end
  end
end
