# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tempo::Helpers::Constants do
  describe 'DEFAULT_TEMPO' do
    it 'is 0.5' do
      expect(described_class::DEFAULT_TEMPO).to eq(0.5)
    end
  end

  describe 'TEMPO_ADJUSTMENT' do
    it 'is 0.05' do
      expect(described_class::TEMPO_ADJUSTMENT).to eq(0.05)
    end
  end

  describe 'MAX_TEMPO_RECORDS' do
    it 'is 300' do
      expect(described_class::MAX_TEMPO_RECORDS).to eq(300)
    end
  end

  describe 'TEMPO_LABELS' do
    it 'contains all five labels' do
      labels = described_class::TEMPO_LABELS.values
      expect(labels).to include(:slow, :deliberate, :moderate, :fast, :rapid)
    end

    it 'covers the full 0.0 to 1.0 range' do
      [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0].each do |value|
        match = described_class::TEMPO_LABELS.any? { |range, _| range.cover?(value) }
        expect(match).to be true
      end
    end
  end

  describe 'MISMATCH_LABELS' do
    it 'contains all four labels' do
      labels = described_class::MISMATCH_LABELS.values
      expect(labels).to include(:synchronized, :slightly_off, :mismatched, :severely_mismatched)
    end

    it 'covers the full 0.0 to 1.0 range' do
      [0.0, 0.05, 0.15, 0.3, 0.6, 1.0].each do |value|
        match = described_class::MISMATCH_LABELS.any? { |range, _| range.cover?(value) }
        expect(match).to be true
      end
    end
  end
end
