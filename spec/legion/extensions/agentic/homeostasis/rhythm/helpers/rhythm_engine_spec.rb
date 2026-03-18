# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::RhythmEngine do
  subject(:engine) { described_class.new }

  let(:fixed_time) { Time.utc(2026, 1, 1, 12, 0, 0) }

  def add_focus_rhythm(eng = engine)
    eng.add_rhythm(name: 'focus rhythm', rhythm_type: :ultradian, dimension: :focus, amplitude: 0.8)
  end

  def add_alertness_rhythm(eng = engine)
    eng.add_rhythm(name: 'alertness rhythm', rhythm_type: :circadian, dimension: :alertness, amplitude: 0.7)
  end

  describe '#add_rhythm' do
    it 'adds an ultradian rhythm and returns a Rhythm' do
      result = add_focus_rhythm
      expect(result).to be_a(Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Rhythm)
      expect(result.rhythm_type).to eq(:ultradian)
      expect(result.period).to eq(5400)
    end

    it 'adds a circadian rhythm with correct period' do
      result = add_alertness_rhythm
      expect(result.period).to eq(86_400)
    end

    it 'adds a custom rhythm with explicit period' do
      result = engine.add_rhythm(
        name: 'micro', rhythm_type: :custom, dimension: :focus,
        period: 900, amplitude: 0.5
      )
      expect(result.period).to eq(900)
    end

    it 'returns nil for custom rhythm without period' do
      result = engine.add_rhythm(
        name: 'bad', rhythm_type: :custom, dimension: :focus, amplitude: 0.5
      )
      expect(result).to be_nil
    end

    it 'enforces MAX_RHYTHMS limit' do
      20.times do |i|
        engine.add_rhythm(name: "r#{i}", rhythm_type: :ultradian,
                          dimension: :focus, amplitude: 0.5)
      end
      result = engine.add_rhythm(name: 'overflow', rhythm_type: :ultradian,
                                 dimension: :focus, amplitude: 0.5)
      expect(result).to be_nil
    end

    it 'assigns unique symbol IDs' do
      r1 = add_focus_rhythm
      r2 = add_alertness_rhythm
      expect(r1.id).not_to eq(r2.id)
    end

    it 'rejects invalid rhythm_type' do
      result = engine.add_rhythm(name: 'bad', rhythm_type: :nonexistent, dimension: :focus, amplitude: 0.5)
      expect(result).to be_nil
    end

    it 'accepts all RHYTHM_TYPES' do
      constants = Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Constants::RHYTHM_TYPES
      constants.each do |rt|
        period = rt == :custom ? 1000 : nil
        result = engine.add_rhythm(name: "r_#{rt}", rhythm_type: rt, dimension: :focus, period: period)
        expect(result).not_to be_nil, "Expected rhythm_type #{rt.inspect} to be accepted"
      end
    end

    it 'rejects invalid dimension' do
      result = engine.add_rhythm(name: 'bad', rhythm_type: :ultradian, dimension: :nonexistent, amplitude: 0.5)
      expect(result).to be_nil
    end

    it 'accepts all COGNITIVE_DIMENSIONS' do
      constants = Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Constants::COGNITIVE_DIMENSIONS
      constants.each do |dim|
        result = engine.add_rhythm(name: "r_#{dim}", rhythm_type: :ultradian, dimension: dim)
        expect(result).not_to be_nil, "Expected dimension #{dim.inspect} to be accepted"
      end
    end
  end

  describe '#remove_rhythm' do
    it 'removes an existing rhythm' do
      rhythm = add_focus_rhythm
      result = engine.remove_rhythm(rhythm_id: rhythm.id)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown id' do
      result = engine.remove_rhythm(rhythm_id: :nonexistent)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#dimension_value' do
    it 'returns 0.0 when no rhythms for dimension' do
      expect(engine.dimension_value(dimension: :focus)).to eq(0.0)
    end

    it 'returns a Float when rhythms exist' do
      add_focus_rhythm
      val = engine.dimension_value(dimension: :focus)
      expect(val).to be_a(Float)
      expect(val).to be_between(0.0, 1.0)
    end

    it 'averages multiple rhythms for same dimension' do
      engine.add_rhythm(name: 'r1', rhythm_type: :ultradian, dimension: :creativity, amplitude: 0.5)
      engine.add_rhythm(name: 'r2', rhythm_type: :ultradian, dimension: :creativity, amplitude: 0.5)
      val = engine.dimension_value(dimension: :creativity)
      expect(val).to be_between(0.0, 1.0)
    end
  end

  describe '#current_state' do
    it 'returns a hash with all cognitive dimensions' do
      state = engine.current_state
      Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Constants::COGNITIVE_DIMENSIONS.each do |dim|
        expect(state).to have_key(dim)
      end
    end

    it 'returns 0.0 for dimensions with no rhythms' do
      state = engine.current_state
      expect(state[:alertness]).to eq(0.0)
    end
  end

  describe '#optimal_for' do
    it 'returns false when no rhythms for dimension' do
      expect(engine.optimal_for(dimension: :focus)).to be false
    end

    it 'returns a boolean' do
      add_focus_rhythm
      expect([true, false]).to include(engine.optimal_for(dimension: :focus))
    end
  end

  describe '#best_time_for' do
    it 'returns nil when no rhythms for dimension' do
      expect(engine.best_time_for(dimension: :social)).to be_nil
    end

    it 'returns a Time object when rhythms exist' do
      add_focus_rhythm
      time = engine.best_time_for(dimension: :focus, within: 3600)
      expect(time).to be_a(Time)
    end

    it 'returns a time within the within window' do
      add_focus_rhythm
      now = Time.now.utc
      time = engine.best_time_for(dimension: :focus, within: 3600)
      expect(time.to_f).to be >= now.to_f
      expect(time.to_f).to be <= now.to_f + 3601
    end
  end

  describe '#synchronize' do
    it 'returns failure for missing rhythm ids' do
      result = engine.synchronize(rhythm_ids: %i[bogus_one bogus_two])
      expect(result[:success]).to be false
    end

    it 'synchronizes phase offsets of multiple rhythms' do
      r1 = add_focus_rhythm
      r2 = engine.add_rhythm(name: 'focus2', rhythm_type: :ultradian, dimension: :focus, amplitude: 0.6)
      result = engine.synchronize(rhythm_ids: [r1.id, r2.id])
      expect(result[:success]).to be true
      expect(result[:synchronized]).to include(r1.id, r2.id)
    end
  end

  describe '#cognitive_profile' do
    it 'returns a hash with all dimensions' do
      add_focus_rhythm
      profile = engine.cognitive_profile
      Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Constants::COGNITIVE_DIMENSIONS.each do |dim|
        expect(profile).to have_key(dim)
      end
    end

    it 'each dimension entry has value, phase_label, amplitude_label, optimal keys' do
      add_focus_rhythm
      profile = engine.cognitive_profile
      expect(profile[:focus]).to include(:value, :phase_label, :amplitude_label, :optimal)
    end
  end

  describe '#peak_dimensions' do
    it 'returns an array' do
      expect(engine.peak_dimensions).to be_an(Array)
    end

    it 'only returns dimensions with at least one peak rhythm' do
      add_focus_rhythm
      peaks = engine.peak_dimensions
      expect(peaks).to be_an(Array)
      peaks.each { |dim| expect(engine.optimal_for(dimension: dim)).to be true }
    end
  end

  describe '#trough_dimensions' do
    it 'returns an array' do
      expect(engine.trough_dimensions).to be_an(Array)
    end
  end

  describe '#to_h' do
    it 'returns rhythm_count, rhythms, and current_state keys' do
      add_focus_rhythm
      h = engine.to_h
      expect(h).to include(:rhythm_count, :rhythms, :current_state)
      expect(h[:rhythm_count]).to eq(1)
    end
  end
end
