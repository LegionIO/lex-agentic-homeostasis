# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::WeatheringEngine do
  subject(:engine) { described_class.new }

  let(:mild_stressor) do
    Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::Stressor.new(
      description:   'Mild task',
      stressor_type: :monotony,
      intensity:     0.3,
      duration:      1800
    )
  end

  let(:heavy_stressor) do
    Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::Stressor.new(
      description:   'Extreme overload',
      stressor_type: :cognitive_overload,
      intensity:     0.9,
      duration:      7200
    )
  end

  describe '#initialize' do
    it 'starts with full integrity' do
      expect(engine.integrity).to eq(1.0)
    end

    it 'starts with zero tempering_level' do
      expect(engine.tempering_level).to eq(0.0)
    end

    it 'starts with zero total_wear' do
      expect(engine.total_wear).to eq(0.0)
    end

    it 'starts with zero total_recovery' do
      expect(engine.total_recovery).to eq(0.0)
    end
  end

  describe '#apply_stressor' do
    it 'reduces integrity after a heavy stressor' do
      engine.apply_stressor(heavy_stressor)
      expect(engine.integrity).to be < 1.0
    end

    it 'increases total_wear' do
      engine.apply_stressor(heavy_stressor)
      expect(engine.total_wear).to be > 0.0
    end

    it 'does not increase tempering for overwhelming stressor' do
      engine.apply_stressor(heavy_stressor)
      expect(engine.tempering_level).to eq(0.0)
    end

    it 'increases tempering for manageable stressor' do
      engine.apply_stressor(mild_stressor)
      expect(engine.tempering_level).to be > 0.0
    end

    it 'returns a hash with integrity key' do
      result = engine.apply_stressor(heavy_stressor)
      expect(result).to have_key(:integrity)
    end

    it 'returns a hash with breaking key' do
      result = engine.apply_stressor(heavy_stressor)
      expect(result).to have_key(:breaking)
    end

    it 'increments stressor_count' do
      engine.apply_stressor(mild_stressor)
      expect(engine.stressor_count).to eq(1)
    end

    it 'wear scales with cumulative impact' do
      small = Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::Stressor.new(
        description: 'tiny', stressor_type: :monotony, intensity: 0.1, duration: 60
      )
      large = Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::Stressor.new(
        description: 'large', stressor_type: :cognitive_overload, intensity: 0.9, duration: 7200
      )
      engine_a = described_class.new
      engine_b = described_class.new
      engine_a.apply_stressor(small)
      engine_b.apply_stressor(large)
      expect(engine_b.total_wear).to be > engine_a.total_wear
    end
  end

  describe '#recover!' do
    before { engine.apply_stressor(heavy_stressor) }

    it 'increases integrity' do
      before = engine.integrity
      engine.recover!(1.0)
      expect(engine.integrity).to be > before
    end

    it 'increases total_recovery' do
      engine.recover!(1.0)
      expect(engine.total_recovery).to be > 0.0
    end

    it 'returns a hash with integrity' do
      result = engine.recover!(1.0)
      expect(result).to have_key(:integrity)
    end

    it 'clamps amount above 1.0' do
      expect { engine.recover!(5.0) }.not_to raise_error
    end

    it 'does not exceed 1.0 integrity' do
      10.times { engine.recover!(1.0) }
      expect(engine.integrity).to be <= 1.0
    end
  end

  describe '#rest!' do
    before { 5.times { engine.apply_stressor(heavy_stressor) } }

    it 'increases integrity more than recover' do
      engine_a = described_class.new
      engine_b = described_class.new
      5.times { engine_a.apply_stressor(heavy_stressor) }
      5.times { engine_b.apply_stressor(heavy_stressor) }
      integrity_before = engine_a.integrity

      engine_a.recover!(1.0)
      engine_b.rest!(1.0)

      recovery_delta = engine_a.integrity - integrity_before
      rest_delta = engine_b.integrity - integrity_before
      expect(rest_delta).to be > recovery_delta
    end

    it 'does not exceed 1.0 integrity' do
      10.times { engine.rest!(1.0) }
      expect(engine.integrity).to be <= 1.0
    end

    it 'increases total_recovery' do
      engine.rest!(1.0)
      expect(engine.total_recovery).to be > 0.0
    end
  end

  describe '#effective_capacity' do
    it 'starts at 1.0 with no tempering' do
      expect(engine.effective_capacity).to be_within(0.001).of(1.0)
    end

    it 'increases above base when tempering is present' do
      20.times { engine.apply_stressor(mild_stressor) }
      expect(engine.tempering_level).to be > 0.0
      expect(engine.effective_capacity).to be > (engine.integrity * 1.0)
    end

    it 'is capped at 1.2' do
      100.times { engine.apply_stressor(mild_stressor) }
      expect(engine.effective_capacity).to be <= 1.2
    end

    it 'decreases as integrity drops' do
      base = engine.effective_capacity
      10.times { engine.apply_stressor(heavy_stressor) }
      expect(engine.effective_capacity).to be < base
    end
  end

  describe '#fragile?' do
    it 'returns false at full integrity' do
      expect(engine.fragile?).to be(false)
    end

    it 'returns true when integrity is at or below CRITICAL_INTEGRITY' do
      100.times { engine.apply_stressor(heavy_stressor) }
      expect(engine.fragile?).to be(true)
    end
  end

  describe '#breaking?' do
    it 'returns false at full integrity' do
      expect(engine.breaking?).to be(false)
    end

    it 'returns true when integrity is at or below BREAKDOWN_INTEGRITY' do
      500.times { engine.apply_stressor(heavy_stressor) }
      expect(engine.breaking?).to be(true)
    end
  end

  describe '#weathering_report' do
    it 'returns all expected keys' do
      report = engine.weathering_report
      expect(report).to have_key(:integrity)
      expect(report).to have_key(:integrity_label)
      expect(report).to have_key(:tempering_level)
      expect(report).to have_key(:weathering_label)
      expect(report).to have_key(:effective_capacity)
      expect(report).to have_key(:total_wear)
      expect(report).to have_key(:total_recovery)
      expect(report).to have_key(:stressor_count)
      expect(report).to have_key(:fragile)
      expect(report).to have_key(:breaking)
      expect(report).to have_key(:recent_stressors)
    end

    it 'includes integrity_label as a string' do
      expect(engine.weathering_report[:integrity_label]).to eq('pristine')
    end

    it 'caps recent_stressors at 5' do
      10.times { engine.apply_stressor(mild_stressor) }
      expect(engine.weathering_report[:recent_stressors].size).to eq(5)
    end
  end

  describe '#to_h' do
    it 'includes integrity, tempering_level, effective_capacity, fragile, breaking' do
      h = engine.to_h
      expect(h).to have_key(:integrity)
      expect(h).to have_key(:tempering_level)
      expect(h).to have_key(:effective_capacity)
      expect(h).to have_key(:fragile)
      expect(h).to have_key(:breaking)
    end
  end

  describe 'MAX_STRESSORS pruning' do
    it 'does not exceed MAX_STRESSORS in memory' do
      constants = Legion::Extensions::Agentic::Homeostasis::Weathering::Helpers::Constants
      (constants::MAX_STRESSORS + 10).times do
        engine.apply_stressor(mild_stressor)
      end
      expect(engine.stressor_count).to be <= constants::MAX_STRESSORS
    end
  end
end
