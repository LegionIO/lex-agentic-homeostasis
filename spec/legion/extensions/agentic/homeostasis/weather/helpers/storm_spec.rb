# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weather::Helpers::Storm do
  subject(:storm) { described_class.new(condition: :stormy) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(storm.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets condition' do
      expect(storm.condition).to eq(:stormy)
    end

    it 'defaults front_ids to empty array' do
      expect(storm.front_ids).to eq([])
    end

    it 'accepts front_ids' do
      s = described_class.new(condition: :foggy, front_ids: %w[abc def])
      expect(s.front_ids).to eq(%w[abc def])
    end

    it 'defaults intensity to 0.5' do
      expect(storm.intensity).to eq(0.5)
    end

    it 'defaults coverage to 0.5' do
      expect(storm.coverage).to eq(0.5)
    end

    it 'clamps intensity above 1.0' do
      s = described_class.new(condition: :clear, intensity: 1.5)
      expect(s.intensity).to eq(1.0)
    end

    it 'clamps intensity below 0.0' do
      s = described_class.new(condition: :clear, intensity: -0.5)
      expect(s.intensity).to eq(0.0)
    end

    it 'initializes empty insight_log' do
      expect(storm.insight_log).to eq([])
    end

    it 'raises ArgumentError for unknown condition' do
      expect { described_class.new(condition: :tornado) }.to raise_error(ArgumentError, /unknown condition/)
    end

    it 'accepts all valid conditions' do
      %i[clear cloudy foggy stormy lightning blizzard].each do |cond|
        expect { described_class.new(condition: cond) }.not_to raise_error
      end
    end
  end

  describe '#intensify!' do
    it 'increases intensity by default rate' do
      initial = storm.intensity
      storm.intensify!
      expect(storm.intensity).to be > initial
    end

    it 'also increases coverage' do
      initial_cov = storm.coverage
      storm.intensify!
      expect(storm.coverage).to be > initial_cov
    end

    it 'clamps intensity at 1.0' do
      s = described_class.new(condition: :stormy, intensity: 0.98)
      s.intensify!(0.5)
      expect(s.intensity).to eq(1.0)
    end
  end

  describe '#dissipate!' do
    it 'decreases intensity by default rate' do
      initial = storm.intensity
      storm.dissipate!
      expect(storm.intensity).to be < initial
    end

    it 'also decreases coverage' do
      initial_cov = storm.coverage
      storm.dissipate!
      expect(storm.coverage).to be < initial_cov
    end

    it 'clamps intensity at 0.0' do
      s = described_class.new(condition: :stormy, intensity: 0.01)
      s.dissipate!(0.5)
      expect(s.intensity).to eq(0.0)
    end
  end

  describe '#lightning_strike!' do
    it 'returns a hash with id, domain, intensity, struck_at' do
      result = storm.lightning_strike!(domain: 'planning')
      expect(result.keys).to include(:id, :domain, :intensity, :struck_at)
    end

    it 'assigns a UUID to the insight' do
      result = storm.lightning_strike!
      expect(result[:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'records insight intensity in [0, 1]' do
      result = storm.lightning_strike!
      expect(result[:intensity]).to be_between(0.0, 1.0)
    end

    it 'appends to insight_log' do
      expect { storm.lightning_strike! }.to change(storm.insight_log, :size).by(1)
    end

    it 'accumulates multiple strikes' do
      3.times { storm.lightning_strike! }
      expect(storm.insight_log.size).to eq(3)
    end

    it 'sets domain in the insight' do
      result = storm.lightning_strike!(domain: 'creativity')
      expect(result[:domain]).to eq('creativity')
    end
  end

  describe '#raging?' do
    it 'returns true when intensity >= 0.75' do
      s = described_class.new(condition: :blizzard, intensity: 0.9)
      expect(s.raging?).to be true
    end

    it 'returns false when intensity < 0.75' do
      expect(storm.raging?).to be false
    end
  end

  describe '#clearing?' do
    it 'returns true when intensity <= 0.25' do
      s = described_class.new(condition: :cloudy, intensity: 0.1)
      expect(s.clearing?).to be true
    end

    it 'returns false when intensity > 0.25' do
      expect(storm.clearing?).to be false
    end
  end

  describe '#clarity_label' do
    it 'returns crystal for 0.0 intensity (fully clear)' do
      s = described_class.new(condition: :clear, intensity: 0.0)
      expect(s.clarity_label).to eq('crystal')
    end

    it 'returns opaque for 1.0 intensity (maximum storm)' do
      s = described_class.new(condition: :blizzard, intensity: 1.0)
      expect(s.clarity_label).to eq('opaque')
    end

    it 'returns intermediate labels for mid-range intensity' do
      s = described_class.new(condition: :foggy, intensity: 0.5)
      expect(%w[hazy murky]).to include(s.clarity_label)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = storm.to_h
      expect(h.keys).to include(:id, :condition, :front_ids, :intensity, :coverage,
                                :raging, :clearing, :clarity, :insight_count, :created_at)
    end

    it 'rounds intensity to 10 decimal places' do
      expect(storm.to_h[:intensity]).to eq(0.5.round(10))
    end

    it 'reports insight_count accurately' do
      storm.lightning_strike!
      storm.lightning_strike!
      expect(storm.to_h[:insight_count]).to eq(2)
    end
  end
end
