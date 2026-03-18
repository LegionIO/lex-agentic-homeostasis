# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/neural_oscillation/runners/neural_oscillation'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Runners::NeuralOscillation do
  let(:network) { Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::OscillationNetwork.new }
  let(:host) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@network, network)
    obj
  end

  describe '#add_oscillator' do
    it 'adds successfully' do
      result = host.add_oscillator(id: :visual)
      expect(result[:success]).to be true
      expect(result[:oscillator][:id]).to eq(:visual)
    end
  end

  describe '#activate_band' do
    it 'activates a band' do
      host.add_oscillator(id: :visual)
      result = host.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.6)
      expect(result[:success]).to be true
      expect(result[:oscillator][:powers][:gamma]).to eq(0.6)
    end

    it 'fails for unknown oscillator' do
      result = host.activate_band(oscillator_id: :nope, band: :gamma)
      expect(result[:success]).to be false
    end
  end

  describe '#suppress_band' do
    it 'suppresses a band' do
      host.add_oscillator(id: :visual)
      host.activate_band(oscillator_id: :visual, band: :alpha, amount: 0.5)
      result = host.suppress_band(oscillator_id: :visual, band: :alpha, amount: 0.3)
      expect(result[:success]).to be true
    end
  end

  describe '#couple_oscillators' do
    it 'couples two oscillators' do
      host.add_oscillator(id: :visual)
      host.add_oscillator(id: :auditory)
      result = host.couple_oscillators(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      expect(result[:success]).to be true
      expect(result[:coupling][:band]).to eq(:gamma)
    end
  end

  describe '#decouple_oscillators' do
    it 'removes a coupling' do
      host.add_oscillator(id: :visual)
      host.add_oscillator(id: :auditory)
      host.couple_oscillators(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      result = host.decouple_oscillators(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      expect(result[:success]).to be true
    end
  end

  describe '#global_rhythm' do
    it 'returns rhythm and state' do
      host.add_oscillator(id: :visual)
      host.activate_band(oscillator_id: :visual, band: :beta, amount: 0.9)
      result = host.global_rhythm
      expect(result[:success]).to be true
      expect(result[:rhythm]).to eq(:beta)
      expect(result[:cognitive_state]).to eq(:focused)
    end
  end

  describe '#synchrony_for_band' do
    it 'returns synchrony level' do
      result = host.synchrony_for_band(band: :gamma)
      expect(result[:success]).to be true
    end
  end

  describe '#desynchronize_band' do
    it 'desynchronizes' do
      result = host.desynchronize_band(band: :alpha)
      expect(result[:success]).to be true
    end
  end

  describe '#update_neural_oscillations' do
    it 'ticks the network' do
      result = host.update_neural_oscillations
      expect(result[:success]).to be true
    end
  end

  describe '#neural_oscillation_stats' do
    it 'returns stats' do
      result = host.neural_oscillation_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:oscillator_count, :coupling_count)
    end
  end
end
