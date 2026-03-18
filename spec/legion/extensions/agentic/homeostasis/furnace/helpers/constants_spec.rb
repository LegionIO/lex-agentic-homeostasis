# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants do
  describe 'ORE_TYPES' do
    it 'contains 5 ore types' do
      expect(described_class::ORE_TYPES.size).to eq(5)
    end

    it 'includes experience, observation, hypothesis, data, intuition' do
      expect(described_class::ORE_TYPES).to include(:experience, :observation, :hypothesis, :data, :intuition)
    end

    it 'is frozen' do
      expect(described_class::ORE_TYPES).to be_frozen
    end
  end

  describe 'ALLOY_TYPES' do
    it 'contains 5 alloy types' do
      expect(described_class::ALLOY_TYPES.size).to eq(5)
    end

    it 'includes insight, wisdom, expertise, synthesis, theory' do
      expect(described_class::ALLOY_TYPES).to include(:insight, :wisdom, :expertise, :synthesis, :theory)
    end

    it 'is frozen' do
      expect(described_class::ALLOY_TYPES).to be_frozen
    end
  end

  describe 'numeric constants' do
    it 'MAX_ORES is 500' do
      expect(described_class::MAX_ORES).to eq(500)
    end

    it 'MAX_CRUCIBLES is 50' do
      expect(described_class::MAX_CRUCIBLES).to eq(50)
    end

    it 'HEAT_RATE is 0.1' do
      expect(described_class::HEAT_RATE).to eq(0.1)
    end

    it 'COOL_RATE is 0.05' do
      expect(described_class::COOL_RATE).to eq(0.05)
    end

    it 'SMELT_THRESHOLD is 0.6' do
      expect(described_class::SMELT_THRESHOLD).to eq(0.6)
    end

    it 'DESTROY_THRESHOLD is 0.95' do
      expect(described_class::DESTROY_THRESHOLD).to eq(0.95)
    end
  end

  describe 'PURITY_LABELS' do
    it 'is frozen' do
      expect(described_class::PURITY_LABELS).to be_frozen
    end

    it 'has 5 entries' do
      expect(described_class::PURITY_LABELS.size).to eq(5)
    end

    it 'maps high purity to :refined' do
      expect(described_class::PURITY_LABELS.find { |r, _| r.cover?(0.9) }.last).to eq(:refined)
    end

    it 'maps low purity to :impure' do
      expect(described_class::PURITY_LABELS.find { |r, _| r.cover?(0.1) }.last).to eq(:impure)
    end
  end

  describe 'TEMPERATURE_LABELS' do
    it 'is frozen' do
      expect(described_class::TEMPERATURE_LABELS).to be_frozen
    end

    it 'has 5 entries' do
      expect(described_class::TEMPERATURE_LABELS.size).to eq(5)
    end

    it 'maps max temperature to :white_hot' do
      expect(described_class::TEMPERATURE_LABELS.find { |r, _| r.cover?(1.0) }.last).to eq(:white_hot)
    end

    it 'maps zero temperature to :cold' do
      expect(described_class::TEMPERATURE_LABELS.find { |r, _| r.cover?(0.0) }.last).to eq(:cold)
    end
  end

  describe '.label_for' do
    it 'returns :refined for purity 0.9' do
      expect(described_class.label_for(described_class::PURITY_LABELS, 0.9)).to eq(:refined)
    end

    it 'returns :impure for purity 0.05' do
      expect(described_class.label_for(described_class::PURITY_LABELS, 0.05)).to eq(:impure)
    end

    it 'returns :crude for purity 0.25' do
      expect(described_class.label_for(described_class::PURITY_LABELS, 0.25)).to eq(:crude)
    end

    it 'returns :raw for purity 0.5' do
      expect(described_class.label_for(described_class::PURITY_LABELS, 0.5)).to eq(:raw)
    end

    it 'returns :processed for purity 0.7' do
      expect(described_class.label_for(described_class::PURITY_LABELS, 0.7)).to eq(:processed)
    end

    it 'clamps above 1.0' do
      result = described_class.label_for(described_class::PURITY_LABELS, 1.5)
      expect(result).to be_a(Symbol)
    end

    it 'clamps below 0.0' do
      result = described_class.label_for(described_class::PURITY_LABELS, -0.5)
      expect(result).to be_a(Symbol)
    end

    it 'returns :white_hot for temperature 1.0' do
      expect(described_class.label_for(described_class::TEMPERATURE_LABELS, 1.0)).to eq(:white_hot)
    end

    it 'returns :cold for temperature 0.1' do
      expect(described_class.label_for(described_class::TEMPERATURE_LABELS, 0.1)).to eq(:cold)
    end
  end
end
