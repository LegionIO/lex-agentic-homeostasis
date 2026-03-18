# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/neural_oscillation/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Client do
  subject(:client) { described_class.new }

  it 'adds oscillators and activates bands' do
    client.add_oscillator(id: :visual)
    result = client.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.8)
    expect(result[:success]).to be true
  end

  it 'reports global rhythm' do
    client.add_oscillator(id: :pfc)
    client.activate_band(oscillator_id: :pfc, band: :beta, amount: 0.9)
    result = client.global_rhythm
    expect(result[:cognitive_state]).to eq(:focused)
  end

  it 'reports stats' do
    result = client.neural_oscillation_stats
    expect(result[:success]).to be true
  end
end
