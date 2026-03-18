# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Core::Runners::Homeostasis do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Core::Client.new }

  let(:tick_results) do
    {
      emotional_evaluation:       { arousal: 0.8, magnitude: 0.7 },
      working_memory_integration: { curiosity_intensity: 0.9 },
      elapsed:                    3.5,
      budget:                     5.0,
      memory_consolidation:       { total: 100, pruned: 20 },
      prediction_engine:          { accuracy: 0.65 },
      post_tick_reflection:       { cognitive_health: 0.7 },
      sensory_processing:         { total_signals: 10, passed: 5 }
    }
  end

  describe '#regulate' do
    it 'returns regulation signals' do
      result = client.regulate(tick_results: tick_results)
      expect(result).to have_key(:signals)
      expect(result[:signals]).not_to be_empty
    end

    it 'returns regulation health' do
      result = client.regulate(tick_results: tick_results)
      expect(result[:regulation_health]).to be_a(Numeric)
      expect(result[:regulation_health]).to be_between(0.0, 1.0)
    end

    it 'tracks allostatic load' do
      result = client.regulate(tick_results: tick_results)
      expect(result[:allostatic_load]).to be_a(Numeric)
    end

    it 'reports worst deviation' do
      result = client.regulate(tick_results: tick_results)
      expect(result).to have_key(:worst_deviation)
    end

    it 'dampens high arousal' do
      result = client.regulate(tick_results: tick_results)
      arousal_signal = result[:signals][:emotional_arousal]
      expect(arousal_signal).not_to be_nil
      expect(arousal_signal[:type]).to eq(:dampen)
    end

    it 'dampens high curiosity' do
      result = client.regulate(tick_results: tick_results)
      curiosity_signal = result[:signals][:curiosity_intensity]
      expect(curiosity_signal).not_to be_nil
      expect(curiosity_signal[:type]).to eq(:dampen)
    end

    it 'handles empty tick results' do
      result = client.regulate(tick_results: {})
      expect(result[:signals]).to be_empty
    end

    it 'accumulates allostatic load over repeated regulation' do
      3.times { client.regulate(tick_results: tick_results) }
      result = client.regulate(tick_results: tick_results)
      expect(result[:allostatic_load]).to be > 0.0
    end
  end

  describe '#modulation_for' do
    before { client.regulate(tick_results: tick_results) }

    it 'returns signal for known subsystem' do
      result = client.modulation_for(subsystem: :emotional_arousal)
      expect(result[:subsystem]).to eq(:emotional_arousal)
      expect(result[:signal]).to have_key(:type)
    end

    it 'returns hold signal for unregulated subsystem' do
      result = client.modulation_for(subsystem: :nonexistent)
      expect(result[:signal][:type]).to eq(:hold)
    end

    it 'includes setpoint info' do
      result = client.modulation_for(subsystem: :emotional_arousal)
      expect(result[:setpoint]).to include(:target, :tolerance)
    end
  end

  describe '#allostatic_status' do
    it 'returns load classification' do
      result = client.allostatic_status
      expect(result[:classification]).to eq(:healthy)
    end

    it 'reports peak load' do
      client.regulate(tick_results: tick_results)
      result = client.allostatic_status
      expect(result).to have_key(:peak_load)
    end
  end

  describe '#regulation_overview' do
    it 'returns comprehensive state' do
      client.regulate(tick_results: tick_results)
      result = client.regulation_overview
      expect(result).to include(:health, :health_label, :allostatic_load, :setpoints, :signals)
    end
  end

  describe '#homeostasis_stats' do
    it 'returns stats summary' do
      client.regulate(tick_results: tick_results)
      result = client.homeostasis_stats
      expect(result).to include(:regulation_count, :regulation_health, :allostatic_load,
                                :subsystems_tracked, :subsystems_deviating)
      expect(result[:regulation_count]).to eq(1)
    end
  end
end
