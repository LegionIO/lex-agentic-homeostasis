# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weather::Helpers::Constants do
  describe 'FRONT_TYPES' do
    it 'includes warm, cold, occluded, stationary' do
      expect(described_class::FRONT_TYPES).to include(:warm, :cold, :occluded, :stationary)
    end

    it 'is frozen' do
      expect(described_class::FRONT_TYPES).to be_frozen
    end
  end

  describe 'CONDITION_TYPES' do
    it 'includes all weather conditions' do
      expect(described_class::CONDITION_TYPES).to include(:clear, :cloudy, :foggy, :stormy, :lightning, :blizzard)
    end

    it 'is frozen' do
      expect(described_class::CONDITION_TYPES).to be_frozen
    end
  end

  describe 'limits' do
    it 'MAX_FRONTS is 100' do
      expect(described_class::MAX_FRONTS).to eq(100)
    end

    it 'MAX_STORMS is 50' do
      expect(described_class::MAX_STORMS).to eq(50)
    end
  end

  describe 'rates' do
    it 'PRESSURE_CHANGE_RATE is 0.05' do
      expect(described_class::PRESSURE_CHANGE_RATE).to eq(0.05)
    end

    it 'DISSIPATION_RATE is 0.03' do
      expect(described_class::DISSIPATION_RATE).to eq(0.03)
    end
  end

  describe 'SEVERITY_LABELS' do
    it 'is frozen' do
      expect(described_class::SEVERITY_LABELS).to be_frozen
    end

    it 'has 6 entries' do
      expect(described_class::SEVERITY_LABELS.size).to eq(6)
    end

    it 'covers the full 0..1 range' do
      all_covered = [0.0, 0.5, 1.0].all? do |v|
        described_class::SEVERITY_LABELS.any? { |e| e[:range].cover?(v) }
      end
      expect(all_covered).to be true
    end
  end

  describe 'CLARITY_LABELS' do
    it 'is frozen' do
      expect(described_class::CLARITY_LABELS).to be_frozen
    end

    it 'has 5 entries' do
      expect(described_class::CLARITY_LABELS.size).to eq(5)
    end

    it 'covers the full 0..1 range' do
      all_covered = [0.0, 0.5, 1.0].all? do |v|
        described_class::CLARITY_LABELS.any? { |e| e[:range].cover?(v) }
      end
      expect(all_covered).to be true
    end
  end

  describe '.label_for' do
    context 'with SEVERITY_LABELS' do
      it 'returns catastrophic for 1.0' do
        expect(described_class.label_for(described_class::SEVERITY_LABELS, 1.0)).to eq('catastrophic')
      end

      it 'returns calm for 0.0' do
        expect(described_class.label_for(described_class::SEVERITY_LABELS, 0.0)).to eq('calm')
      end

      it 'returns severe for 0.8' do
        expect(described_class.label_for(described_class::SEVERITY_LABELS, 0.8)).to eq('severe')
      end

      it 'returns moderate for 0.6' do
        expect(described_class.label_for(described_class::SEVERITY_LABELS, 0.6)).to eq('moderate')
      end

      it 'clamps values above 1.0' do
        expect(described_class.label_for(described_class::SEVERITY_LABELS, 1.5)).to eq('catastrophic')
      end

      it 'clamps values below 0.0' do
        expect(described_class.label_for(described_class::SEVERITY_LABELS, -0.5)).to eq('calm')
      end
    end

    context 'with CLARITY_LABELS' do
      it 'returns crystal for 1.0' do
        expect(described_class.label_for(described_class::CLARITY_LABELS, 1.0)).to eq('crystal')
      end

      it 'returns opaque for 0.0' do
        expect(described_class.label_for(described_class::CLARITY_LABELS, 0.0)).to eq('opaque')
      end

      it 'returns clear for 0.75' do
        expect(described_class.label_for(described_class::CLARITY_LABELS, 0.75)).to eq('clear')
      end

      it 'returns hazy for 0.55' do
        expect(described_class.label_for(described_class::CLARITY_LABELS, 0.55)).to eq('hazy')
      end

      it 'returns murky for 0.35' do
        expect(described_class.label_for(described_class::CLARITY_LABELS, 0.35)).to eq('murky')
      end
    end
  end
end
