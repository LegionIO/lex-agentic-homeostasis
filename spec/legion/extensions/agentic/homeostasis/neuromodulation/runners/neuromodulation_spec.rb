# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/neuromodulation/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Runners::Neuromodulation do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Client.new }

  describe '#boost_modulator' do
    it 'returns success true' do
      result = client.boost_modulator(name: :dopamine, amount: 0.1)
      expect(result[:success]).to be true
    end

    it 'returns updated level' do
      result = client.boost_modulator(name: :dopamine, amount: 0.1)
      expect(result[:level]).to be > 0.5
    end

    it 'returns state label' do
      result = client.boost_modulator(name: :dopamine, amount: 0.1)
      expect(result[:state]).to be_a(Symbol)
    end

    it 'returns error for unknown modulator' do
      result = client.boost_modulator(name: :cortisol, amount: 0.1)
      expect(result[:success]).to be false
      expect(result[:error]).to include('cortisol')
    end

    it 'accepts string modulator name' do
      result = client.boost_modulator(name: 'serotonin', amount: 0.1)
      expect(result[:success]).to be true
    end
  end

  describe '#suppress_modulator' do
    it 'returns success true' do
      result = client.suppress_modulator(name: :serotonin, amount: 0.1)
      expect(result[:success]).to be true
    end

    it 'decreases level' do
      result = client.suppress_modulator(name: :serotonin, amount: 0.1)
      expect(result[:level]).to be < 0.5
    end

    it 'returns error for unknown modulator' do
      result = client.suppress_modulator(name: :adrenaline, amount: 0.1)
      expect(result[:success]).to be false
    end
  end

  describe '#modulator_level' do
    it 'returns current level' do
      result = client.modulator_level(name: :norepinephrine)
      expect(result[:success]).to be true
      expect(result[:level]).to eq(0.5)
    end

    it 'returns error for unknown modulator' do
      result = client.modulator_level(name: :unknown)
      expect(result[:success]).to be false
    end
  end

  describe '#all_modulator_levels' do
    it 'returns all four modulators' do
      result = client.all_modulator_levels
      expect(result[:success]).to be true
      expect(result[:levels].keys).to contain_exactly(:dopamine, :serotonin, :norepinephrine, :acetylcholine)
    end

    it 'reflects changes after boost' do
      client.boost_modulator(name: :dopamine, amount: 0.2)
      result = client.all_modulator_levels
      expect(result[:levels][:dopamine]).to be > 0.5
    end
  end

  describe '#cognitive_influence' do
    it 'returns all six cognitive properties' do
      result = client.cognitive_influence
      expect(result[:success]).to be true
      influences = result[:influences]
      expect(influences).to have_key(:learning_rate_modifier)
      expect(influences).to have_key(:attention_precision)
      expect(influences).to have_key(:exploration_bias)
      expect(influences).to have_key(:patience_factor)
      expect(influences).to have_key(:memory_encoding_strength)
      expect(influences).to have_key(:arousal_level)
    end
  end

  describe '#is_optimal' do
    it 'returns true at default level' do
      result = client.is_optimal(name: :dopamine)
      expect(result[:success]).to be true
      expect(result[:optimal]).to be true
    end

    it 'returns false when out of range' do
      client.boost_modulator(name: :dopamine, amount: 0.5)
      result = client.is_optimal(name: :dopamine)
      expect(result[:optimal]).to be false
    end

    it 'includes range string' do
      result = client.is_optimal(name: :serotonin)
      expect(result[:range]).to be_a(String)
    end

    it 'returns error for unknown modulator' do
      result = client.is_optimal(name: :cortisol)
      expect(result[:success]).to be false
    end
  end

  describe '#system_balance' do
    it 'returns fully_balanced at default' do
      result = client.system_balance
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:fully_balanced)
      expect(result[:score]).to eq(1.0)
    end

    it 'returns imbalanced when all are out of range' do
      client.boost_modulator(name: :dopamine,       amount: 0.5)
      client.boost_modulator(name: :norepinephrine, amount: 0.5)
      client.suppress_modulator(name: :serotonin,      amount: 0.4)
      client.suppress_modulator(name: :acetylcholine,  amount: 0.4)
      result = client.system_balance
      expect(result[:score]).to be < 1.0
    end

    it 'returns state for each modulator' do
      result = client.system_balance
      expect(result[:states].keys).to contain_exactly(:dopamine, :serotonin, :norepinephrine, :acetylcholine)
    end
  end

  describe '#modulator_history' do
    it 'returns empty events initially' do
      result = client.modulator_history(name: :dopamine)
      expect(result[:success]).to be true
      expect(result[:events]).to be_empty
    end

    it 'returns events after changes' do
      client.boost_modulator(name: :dopamine, amount: 0.1)
      client.suppress_modulator(name: :dopamine, amount: 0.05)
      result = client.modulator_history(name: :dopamine)
      expect(result[:events].size).to eq(2)
    end

    it 'respects the limit parameter' do
      10.times { client.boost_modulator(name: :dopamine, amount: 0.001) }
      result = client.modulator_history(name: :dopamine, limit: 3)
      expect(result[:events].size).to eq(3)
    end

    it 'returns error for unknown modulator' do
      result = client.modulator_history(name: :unknown)
      expect(result[:success]).to be false
    end
  end

  describe '#update_neuromodulation' do
    it 'returns success' do
      result = client.update_neuromodulation
      expect(result[:success]).to be true
      expect(result[:action]).to eq(:drift_tick)
    end

    it 'returns current levels after drift' do
      result = client.update_neuromodulation
      expect(result[:levels].keys).to contain_exactly(:dopamine, :serotonin, :norepinephrine, :acetylcholine)
    end

    it 'nudges boosted modulators toward baseline' do
      client.boost_modulator(name: :dopamine, amount: 0.3)
      level_after_boost = client.modulator_level(name: :dopamine)[:level]
      client.update_neuromodulation
      level_after_tick = client.modulator_level(name: :dopamine)[:level]
      expect(level_after_tick).to be < level_after_boost
    end
  end

  describe '#neuromodulation_stats' do
    it 'returns full system snapshot' do
      result = client.neuromodulation_stats
      expect(result[:success]).to be true
      expect(result[:system]).to have_key(:modulators)
      expect(result[:system]).to have_key(:influences)
      expect(result[:system]).to have_key(:balance)
    end
  end
end
