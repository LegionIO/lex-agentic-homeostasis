# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Constants do
  describe 'GRAIN_TYPES' do
    it 'contains the expected types' do
      expect(described_class::GRAIN_TYPES).to include(:attention, :focus, :patience, :willpower, :creativity)
    end

    it 'has 5 types' do
      expect(described_class::GRAIN_TYPES.size).to eq(5)
    end

    it 'is frozen' do
      expect(described_class::GRAIN_TYPES).to be_frozen
    end
  end

  describe 'FLOW_STATES' do
    it 'contains the expected states' do
      expect(described_class::FLOW_STATES).to include(:flowing, :blocked, :empty, :full, :paused)
    end

    it 'has 5 states' do
      expect(described_class::FLOW_STATES.size).to eq(5)
    end

    it 'is frozen' do
      expect(described_class::FLOW_STATES).to be_frozen
    end
  end

  describe 'numeric constants' do
    it 'MAX_HOURGLASSES is 100' do
      expect(described_class::MAX_HOURGLASSES).to eq(100)
    end

    it 'MAX_GRAINS is 500' do
      expect(described_class::MAX_GRAINS).to eq(500)
    end

    it 'FLOW_RATE is 0.05' do
      expect(described_class::FLOW_RATE).to eq(0.05)
    end

    it 'BLOCKAGE_CHANCE is 0.1' do
      expect(described_class::BLOCKAGE_CHANCE).to eq(0.1)
    end
  end

  describe 'URGENCY_LABELS' do
    it 'is an array of hashes with range and label' do
      described_class::URGENCY_LABELS.each do |entry|
        expect(entry).to have_key(:range)
        expect(entry).to have_key(:label)
      end
    end

    it 'covers the full [0.0, 1.0] range' do
      sample_values = [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
      sample_values.each do |v|
        found = described_class::URGENCY_LABELS.find { |e| e[:range].cover?(v) }
        expect(found).not_to be_nil, "No URGENCY_LABELS entry for value #{v}"
      end
    end

    it 'includes critical label for high urgency' do
      entry = described_class::URGENCY_LABELS.find { |e| e[:range].cover?(0.9) }
      expect(entry[:label]).to eq('critical')
    end

    it 'includes relaxed label for low urgency' do
      entry = described_class::URGENCY_LABELS.find { |e| e[:range].cover?(0.1) }
      expect(entry[:label]).to eq('relaxed')
    end
  end

  describe 'FULLNESS_LABELS' do
    it 'is an array of hashes with range and label' do
      described_class::FULLNESS_LABELS.each do |entry|
        expect(entry).to have_key(:range)
        expect(entry).to have_key(:label)
      end
    end

    it 'covers the full [0.0, 1.0] range' do
      sample_values = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
      sample_values.each do |v|
        found = described_class::FULLNESS_LABELS.find { |e| e[:range].cover?(v) }
        expect(found).not_to be_nil, "No FULLNESS_LABELS entry for value #{v}"
      end
    end

    it 'includes overflowing for near-full values' do
      entry = described_class::FULLNESS_LABELS.find { |e| e[:range].cover?(0.95) }
      expect(entry[:label]).to eq('overflowing')
    end

    it 'includes empty label for very low values' do
      entry = described_class::FULLNESS_LABELS.find { |e| e[:range].cover?(0.05) }
      expect(entry[:label]).to eq('empty')
    end
  end

  describe '.label_for' do
    it 'returns the correct urgency label for a value' do
      expect(described_class.label_for(:URGENCY_LABELS, 0.9)).to eq('critical')
    end

    it 'returns the correct urgency label for moderate value' do
      expect(described_class.label_for(:URGENCY_LABELS, 0.5)).to eq('moderate')
    end

    it 'returns the correct fullness label for overflowing' do
      expect(described_class.label_for(:FULLNESS_LABELS, 0.95)).to eq('overflowing')
    end

    it 'returns the correct fullness label for empty' do
      expect(described_class.label_for(:FULLNESS_LABELS, 0.05)).to eq('empty')
    end

    it 'clamps value above 1.0 to 1.0' do
      expect(described_class.label_for(:URGENCY_LABELS, 2.0)).to be_a(String)
    end

    it 'clamps value below 0.0 to 0.0' do
      expect(described_class.label_for(:URGENCY_LABELS, -0.5)).to be_a(String)
    end
  end
end
