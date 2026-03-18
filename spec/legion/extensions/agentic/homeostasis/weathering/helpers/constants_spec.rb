# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::Constants do
  describe 'numeric constants' do
    it 'defines MAX_STRESSORS' do
      expect(described_class::MAX_STRESSORS).to eq(200)
    end

    it 'defines MAX_EVENTS' do
      expect(described_class::MAX_EVENTS).to eq(500)
    end

    it 'defines DEFAULT_INTEGRITY as 1.0' do
      expect(described_class::DEFAULT_INTEGRITY).to eq(1.0)
    end

    it 'defines WEAR_RATE' do
      expect(described_class::WEAR_RATE).to eq(0.02)
    end

    it 'defines RECOVERY_RATE' do
      expect(described_class::RECOVERY_RATE).to eq(0.01)
    end

    it 'defines TEMPERING_RATE' do
      expect(described_class::TEMPERING_RATE).to eq(0.03)
    end

    it 'defines TEMPERING_THRESHOLD' do
      expect(described_class::TEMPERING_THRESHOLD).to eq(0.4)
    end

    it 'defines CRITICAL_INTEGRITY' do
      expect(described_class::CRITICAL_INTEGRITY).to eq(0.3)
    end

    it 'defines BREAKDOWN_INTEGRITY' do
      expect(described_class::BREAKDOWN_INTEGRITY).to eq(0.1)
    end
  end

  describe 'STRESSOR_TYPES' do
    it 'contains all 8 stressor types' do
      expect(described_class::STRESSOR_TYPES.size).to eq(8)
    end

    it 'includes :cognitive_overload' do
      expect(described_class::STRESSOR_TYPES).to include(:cognitive_overload)
    end

    it 'includes :emotional_strain' do
      expect(described_class::STRESSOR_TYPES).to include(:emotional_strain)
    end

    it 'includes :decision_fatigue' do
      expect(described_class::STRESSOR_TYPES).to include(:decision_fatigue)
    end

    it 'includes :conflict_exposure' do
      expect(described_class::STRESSOR_TYPES).to include(:conflict_exposure)
    end

    it 'includes :uncertainty' do
      expect(described_class::STRESSOR_TYPES).to include(:uncertainty)
    end

    it 'includes :time_pressure' do
      expect(described_class::STRESSOR_TYPES).to include(:time_pressure)
    end

    it 'includes :monotony' do
      expect(described_class::STRESSOR_TYPES).to include(:monotony)
    end

    it 'includes :complexity' do
      expect(described_class::STRESSOR_TYPES).to include(:complexity)
    end

    it 'is frozen' do
      expect(described_class::STRESSOR_TYPES).to be_frozen
    end
  end

  describe '.integrity_label' do
    it 'returns pristine for 1.0' do
      expect(described_class.integrity_label(1.0)).to eq('pristine')
    end

    it 'returns pristine for 0.8' do
      expect(described_class.integrity_label(0.8)).to eq('pristine')
    end

    it 'returns strong for 0.7' do
      expect(described_class.integrity_label(0.7)).to eq('strong')
    end

    it 'returns strong for 0.6' do
      expect(described_class.integrity_label(0.6)).to eq('strong')
    end

    it 'returns worn for 0.5' do
      expect(described_class.integrity_label(0.5)).to eq('worn')
    end

    it 'returns fragile for 0.25' do
      expect(described_class.integrity_label(0.25)).to eq('fragile')
    end

    it 'returns breaking for 0.1' do
      expect(described_class.integrity_label(0.1)).to eq('breaking')
    end

    it 'returns breaking for 0.0' do
      expect(described_class.integrity_label(0.0)).to eq('breaking')
    end
  end

  describe '.weathering_label' do
    it 'returns tempered for 0.9' do
      expect(described_class.weathering_label(0.9)).to eq('tempered')
    end

    it 'returns tempered for 0.7' do
      expect(described_class.weathering_label(0.7)).to eq('tempered')
    end

    it 'returns resilient for 0.6' do
      expect(described_class.weathering_label(0.6)).to eq('resilient')
    end

    it 'returns stable for 0.4' do
      expect(described_class.weathering_label(0.4)).to eq('stable')
    end

    it 'returns weathered for 0.2' do
      expect(described_class.weathering_label(0.2)).to eq('weathered')
    end

    it 'returns eroded for 0.05' do
      expect(described_class.weathering_label(0.05)).to eq('eroded')
    end

    it 'returns eroded for 0.0' do
      expect(described_class.weathering_label(0.0)).to eq('eroded')
    end
  end
end
