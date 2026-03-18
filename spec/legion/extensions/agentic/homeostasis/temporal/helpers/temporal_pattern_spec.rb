# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Temporal::Helpers::TemporalPattern do
  subject(:pattern) { described_class.new(domain: :ops, event: :deploy) }

  describe '#add_observation' do
    it 'requires at least 2 timestamps' do
      pattern.add_observation([Time.now.utc])
      expect(pattern.observation_count).to eq(0)
    end

    it 'computes mean interval' do
      base = Time.now.utc
      timestamps = (0..5).map { |i| base + (i * 60) }
      pattern.add_observation(timestamps)
      expect(pattern.mean_interval).to be_within(1.0).of(60.0)
    end

    it 'classifies periodic pattern with regular intervals' do
      base = Time.now.utc
      timestamps = (0..10).map { |i| base + (i * 60) }
      pattern.add_observation(timestamps)
      expect(pattern.pattern_type).to eq(:periodic)
    end

    it 'classifies random pattern with irregular intervals' do
      base = Time.now.utc
      timestamps = [base, base + 5, base + 100, base + 105, base + 500, base + 502, base + 1000]
      pattern.add_observation(timestamps)
      expect(%i[bursty random]).to include(pattern.pattern_type)
    end
  end

  describe '#predict_next' do
    it 'returns nil with insufficient observations' do
      base = Time.now.utc
      pattern.add_observation([base, base + 60])
      expect(pattern.predict_next).to be_nil
    end

    it 'predicts next occurrence for periodic pattern' do
      base = Time.now.utc
      timestamps = (0..10).map { |i| base + (i * 60) }
      pattern.add_observation(timestamps)
      prediction = pattern.predict_next(from: base + 660)
      expect(prediction).to include(:predicted_at, :confidence, :pattern)
    end
  end

  describe '#prediction_accuracy' do
    it 'returns 0.0 with no predictions' do
      expect(pattern.prediction_accuracy).to eq(0.0)
    end
  end

  describe '#record_actual' do
    it 'tracks accuracy' do
      base = Time.now.utc
      timestamps = (0..10).map { |i| base + (i * 60) }
      pattern.add_observation(timestamps)
      prediction = pattern.predict_next(from: timestamps.last)
      pattern.record_actual(prediction[:predicted_at])
      expect(pattern.prediction_accuracy).to eq(1.0)
    end
  end

  describe '#periodic?' do
    it 'returns true for periodic pattern' do
      base = Time.now.utc
      timestamps = (0..10).map { |i| base + (i * 60) }
      pattern.add_observation(timestamps)
      expect(pattern.periodic?).to be true
    end
  end

  describe '#to_h' do
    it 'returns complete hash' do
      h = pattern.to_h
      expect(h).to include(:domain, :event, :pattern_type, :mean_interval,
                           :observation_count, :accuracy)
    end
  end
end
