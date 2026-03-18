# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/neuromodulation/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:boost_modulator)
    expect(client).to respond_to(:suppress_modulator)
    expect(client).to respond_to(:modulator_level)
    expect(client).to respond_to(:all_modulator_levels)
    expect(client).to respond_to(:cognitive_influence)
    expect(client).to respond_to(:is_optimal)
    expect(client).to respond_to(:system_balance)
    expect(client).to respond_to(:modulator_history)
    expect(client).to respond_to(:update_neuromodulation)
    expect(client).to respond_to(:neuromodulation_stats)
  end

  it 'accepts an injected system' do
    system = Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Helpers::ModulatorSystem.new
    system.boost(:dopamine, 0.3)
    c = described_class.new(system: system)
    result = c.modulator_level(name: :dopamine)
    expect(result[:level]).to be > 0.5
  end

  it 'maintains state across calls' do
    client.boost_modulator(name: :acetylcholine, amount: 0.2)
    level_result = client.modulator_level(name: :acetylcholine)
    expect(level_result[:level]).to be_within(0.001).of(0.7)
  end

  it 'round-trips a full neuromodulation cycle' do
    client.boost_modulator(name: :dopamine, amount: 0.15)
    client.suppress_modulator(name: :serotonin, amount: 0.1)
    ci = client.cognitive_influence
    expect(ci[:influences][:exploration_bias]).to be > 0.5
    expect(ci[:influences][:patience_factor]).to be < 0.5
    client.update_neuromodulation
    stats = client.neuromodulation_stats
    expect(stats[:system][:modulators][:dopamine][:level]).to be_a(Float)
  end
end
