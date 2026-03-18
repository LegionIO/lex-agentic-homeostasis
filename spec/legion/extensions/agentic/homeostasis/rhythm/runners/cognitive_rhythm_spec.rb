# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Rhythm::Runners::CognitiveRhythm do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#add_cognitive_rhythm' do
    it 'adds an ultradian rhythm successfully' do
      result = runner.add_cognitive_rhythm(
        name: 'focus cycle', rhythm_type: :ultradian, dimension: :focus
      )
      expect(result[:success]).to be true
      expect(result[:rhythm_id]).to be_a(Symbol)
      expect(result[:dimension]).to eq(:focus)
    end

    it 'adds a circadian rhythm' do
      result = runner.add_cognitive_rhythm(
        name: 'daily energy', rhythm_type: :circadian, dimension: :alertness
      )
      expect(result[:success]).to be true
    end

    it 'adds a custom rhythm with explicit period' do
      result = runner.add_cognitive_rhythm(
        name: 'micro cycle', rhythm_type: :custom, dimension: :creativity,
        period: 900, amplitude: 0.6
      )
      expect(result[:success]).to be true
    end

    it 'returns failure for custom rhythm without period' do
      result = runner.add_cognitive_rhythm(
        name: 'bad', rhythm_type: :custom, dimension: :focus
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:limit_reached_or_invalid)
    end

    it 'accepts extra kwargs via splat' do
      result = runner.add_cognitive_rhythm(
        name: 'x', rhythm_type: :ultradian, dimension: :focus,
        extra_param: 'ignored'
      )
      expect(result[:success]).to be true
    end
  end

  describe '#remove_cognitive_rhythm' do
    it 'removes an existing rhythm' do
      added = runner.add_cognitive_rhythm(
        name: 'temp', rhythm_type: :ultradian, dimension: :focus
      )
      result = runner.remove_cognitive_rhythm(rhythm_id: added[:rhythm_id])
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown rhythm id' do
      result = runner.remove_cognitive_rhythm(rhythm_id: :nonexistent)
      expect(result[:success]).to be false
    end
  end

  describe '#current_rhythm_state' do
    it 'returns success with state hash' do
      result = runner.current_rhythm_state
      expect(result[:success]).to be true
      expect(result[:state]).to be_a(Hash)
    end

    it 'state hash contains all cognitive dimensions' do
      result = runner.current_rhythm_state
      Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Constants::COGNITIVE_DIMENSIONS.each do |dim|
        expect(result[:state]).to have_key(dim)
      end
    end
  end

  describe '#dimension_rhythm_value' do
    it 'returns 0.0 for empty dimension' do
      result = runner.dimension_rhythm_value(dimension: :social)
      expect(result[:success]).to be true
      expect(result[:value]).to eq(0.0)
    end

    it 'returns value for dimension with rhythm' do
      runner.add_cognitive_rhythm(name: 'r', rhythm_type: :ultradian, dimension: :analytical)
      result = runner.dimension_rhythm_value(dimension: :analytical)
      expect(result[:success]).to be true
      expect(result[:value]).to be_between(0.0, 1.0)
    end
  end

  describe '#optimal_for_task' do
    it 'returns optimal boolean for dimension' do
      runner.add_cognitive_rhythm(name: 'r', rhythm_type: :ultradian, dimension: :focus)
      result = runner.optimal_for_task(dimension: :focus)
      expect(result[:success]).to be true
      expect([true, false]).to include(result[:optimal])
    end

    it 'returns false for dimension with no rhythms' do
      result = runner.optimal_for_task(dimension: :emotional)
      expect(result[:success]).to be true
      expect(result[:optimal]).to be false
    end
  end

  describe '#best_time_for_task' do
    it 'returns failure for dimension with no rhythms' do
      result = runner.best_time_for_task(dimension: :social)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:no_rhythms_for_dimension)
    end

    it 'returns best_time ISO8601 string for dimension with rhythms' do
      runner.add_cognitive_rhythm(name: 'r', rhythm_type: :ultradian, dimension: :creativity)
      result = runner.best_time_for_task(dimension: :creativity)
      expect(result[:success]).to be true
      expect(result[:best_time]).to be_a(String)
      expect(result[:within_seconds]).to eq(3600)
    end

    it 'accepts custom within parameter' do
      runner.add_cognitive_rhythm(name: 'r', rhythm_type: :ultradian, dimension: :focus)
      result = runner.best_time_for_task(dimension: :focus, within: 7200)
      expect(result[:within_seconds]).to eq(7200)
    end
  end

  describe '#cognitive_rhythm_profile' do
    it 'returns a profile hash' do
      result = runner.cognitive_rhythm_profile
      expect(result[:success]).to be true
      expect(result[:profile]).to be_a(Hash)
    end

    it 'profile contains all cognitive dimensions' do
      result = runner.cognitive_rhythm_profile
      Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Constants::COGNITIVE_DIMENSIONS.each do |dim|
        expect(result[:profile]).to have_key(dim)
      end
    end
  end

  describe '#peak_cognitive_dimensions' do
    it 'returns success with dimensions array and count' do
      result = runner.peak_cognitive_dimensions
      expect(result[:success]).to be true
      expect(result[:dimensions]).to be_an(Array)
      expect(result[:count]).to eq(result[:dimensions].size)
    end
  end

  describe '#trough_cognitive_dimensions' do
    it 'returns success with dimensions array and count' do
      result = runner.trough_cognitive_dimensions
      expect(result[:success]).to be true
      expect(result[:dimensions]).to be_an(Array)
      expect(result[:count]).to eq(result[:dimensions].size)
    end
  end

  describe '#cognitive_rhythm_stats' do
    it 'returns stats with rhythm_count' do
      result = runner.cognitive_rhythm_stats
      expect(result[:success]).to be true
      expect(result).to include(:rhythm_count, :rhythms, :current_state)
    end

    it 'rhythm_count increases after adding rhythms' do
      runner.add_cognitive_rhythm(name: 'r1', rhythm_type: :ultradian, dimension: :focus)
      runner.add_cognitive_rhythm(name: 'r2', rhythm_type: :circadian, dimension: :alertness)
      result = runner.cognitive_rhythm_stats
      expect(result[:rhythm_count]).to eq(2)
    end
  end
end
