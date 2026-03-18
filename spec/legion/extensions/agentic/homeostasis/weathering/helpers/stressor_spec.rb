# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::Stressor do
  let(:stressor) do
    described_class.new(
      description:   'Heavy parallel task load',
      stressor_type: :cognitive_overload,
      intensity:     0.7,
      duration:      3600,
      domain:        'work'
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(stressor.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns description' do
      expect(stressor.description).to eq('Heavy parallel task load')
    end

    it 'assigns stressor_type' do
      expect(stressor.stressor_type).to eq(:cognitive_overload)
    end

    it 'assigns intensity' do
      expect(stressor.intensity).to eq(0.7)
    end

    it 'assigns duration' do
      expect(stressor.duration).to eq(3600)
    end

    it 'assigns domain' do
      expect(stressor.domain).to eq('work')
    end

    it 'records a timestamp' do
      expect(stressor.recorded_at).to be_a(Time)
    end

    it 'clamps intensity above 1.0 to 1.0' do
      s = described_class.new(description: 'test', stressor_type: :monotony, intensity: 1.5, duration: 60)
      expect(s.intensity).to eq(1.0)
    end

    it 'clamps intensity below 0.0 to 0.0' do
      s = described_class.new(description: 'test', stressor_type: :monotony, intensity: -0.3, duration: 60)
      expect(s.intensity).to eq(0.0)
    end

    it 'defaults domain to nil when not provided' do
      s = described_class.new(description: 'test', stressor_type: :complexity, intensity: 0.5, duration: 60)
      expect(s.domain).to be_nil
    end

    it 'falls back to :cognitive_overload for unknown stressor type' do
      s = described_class.new(description: 'test', stressor_type: :banana, intensity: 0.5, duration: 60)
      expect(s.stressor_type).to eq(:cognitive_overload)
    end

    it 'accepts string stressor type and converts to symbol' do
      s = described_class.new(description: 'test', stressor_type: 'monotony', intensity: 0.5, duration: 60)
      expect(s.stressor_type).to eq(:monotony)
    end

    it 'floors negative duration to 0' do
      s = described_class.new(description: 'test', stressor_type: :uncertainty, intensity: 0.3, duration: -100)
      expect(s.duration).to eq(0.0)
    end
  end

  describe '#cumulative_impact' do
    it 'computes intensity * (duration / 3600)' do
      expect(stressor.cumulative_impact).to be_within(0.0001).of(0.7)
    end

    it 'rounds to 10 decimal places' do
      expect(stressor.cumulative_impact.to_s).to match(/\A\d+\.\d+\z/)
    end

    it 'clamps at 1.0 for very long durations' do
      s = described_class.new(description: 'long', stressor_type: :time_pressure, intensity: 1.0, duration: 100_000)
      expect(s.cumulative_impact).to eq(1.0)
    end

    it 'returns 0 for zero duration' do
      s = described_class.new(description: 'instant', stressor_type: :uncertainty, intensity: 0.9, duration: 0)
      expect(s.cumulative_impact).to eq(0.0)
    end
  end

  describe '#manageable?' do
    it 'returns true when intensity is at or below TEMPERING_THRESHOLD' do
      s = described_class.new(description: 'mild', stressor_type: :monotony, intensity: 0.4, duration: 60)
      expect(s.manageable?).to be(true)
    end

    it 'returns false when intensity exceeds TEMPERING_THRESHOLD' do
      s = described_class.new(description: 'heavy', stressor_type: :cognitive_overload, intensity: 0.6, duration: 60)
      expect(s.manageable?).to be(false)
    end
  end

  describe '#overwhelming?' do
    it 'returns true when intensity >= 0.8' do
      s = described_class.new(description: 'extreme', stressor_type: :conflict_exposure, intensity: 0.9, duration: 60)
      expect(s.overwhelming?).to be(true)
    end

    it 'returns false when intensity < 0.8' do
      s = described_class.new(description: 'moderate', stressor_type: :complexity, intensity: 0.7, duration: 60)
      expect(s.overwhelming?).to be(false)
    end
  end

  describe '#to_h' do
    subject(:hash) { stressor.to_h }

    it 'includes id' do
      expect(hash[:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'includes description' do
      expect(hash[:description]).to eq('Heavy parallel task load')
    end

    it 'includes stressor_type' do
      expect(hash[:stressor_type]).to eq(:cognitive_overload)
    end

    it 'includes intensity' do
      expect(hash[:intensity]).to eq(0.7)
    end

    it 'includes duration' do
      expect(hash[:duration]).to eq(3600)
    end

    it 'includes domain' do
      expect(hash[:domain]).to eq('work')
    end

    it 'includes cumulative_impact' do
      expect(hash[:cumulative_impact]).to be_a(Float)
    end

    it 'includes manageable flag' do
      expect(hash[:manageable]).to be(false)
    end

    it 'includes overwhelming flag' do
      expect(hash[:overwhelming]).to be(false)
    end

    it 'includes recorded_at as ISO8601 string' do
      expect(hash[:recorded_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end
end
