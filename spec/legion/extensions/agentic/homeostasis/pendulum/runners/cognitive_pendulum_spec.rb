# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/pendulum/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Pendulum::Runners::CognitivePendulum do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Pendulum::Client.new }

  describe '#create_pendulum' do
    it 'returns success with valid pole_pair' do
      result = client.create_pendulum(pole_pair: :certainty_doubt)
      expect(result[:success]).to be true
    end

    it 'returns a pendulum_id uuid' do
      result = client.create_pendulum(pole_pair: :focus_diffusion)
      expect(result[:pendulum_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'echoes the pole_pair' do
      result = client.create_pendulum(pole_pair: :analysis_intuition)
      expect(result[:pole_pair]).to eq(:analysis_intuition)
    end

    it 'returns the amplitude' do
      result = client.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.7)
      expect(result[:amplitude]).to eq(0.7)
    end

    it 'returns error for invalid pole_pair' do
      result = client.create_pendulum(pole_pair: :bogus)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_pole_pair)
    end

    it 'includes valid_pairs in error response' do
      result = client.create_pendulum(pole_pair: :bogus)
      expect(result[:valid_pairs]).to be_an(Array)
    end

    it 'returns argument_error for invalid amplitude' do
      result = client.create_pendulum(pole_pair: :certainty_doubt, amplitude: 5.0)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:argument_error)
    end

    it 'returns argument_error for non-positive period' do
      result = client.create_pendulum(pole_pair: :certainty_doubt, period: -1.0)
      expect(result[:success]).to be false
    end

    it 'accepts all five pole pairs' do
      %i[certainty_doubt focus_diffusion analysis_intuition approach_avoidance convergent_divergent].each do |pair|
        result = client.create_pendulum(pole_pair: pair)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#swing' do
    let(:pendulum_id) { client.create_pendulum(pole_pair: :certainty_doubt)[:pendulum_id] }

    it 'returns success for valid pendulum' do
      result = client.swing(pendulum_id: pendulum_id, force: 0.5)
      expect(result[:success]).to be true
    end

    it 'returns the current_position' do
      result = client.swing(pendulum_id: pendulum_id, force: 0.5)
      expect(result[:current_position]).to eq(0.5)
    end

    it 'returns the dominant_pole' do
      result = client.swing(pendulum_id: pendulum_id, force: 0.8)
      expect(result).to have_key(:dominant_pole)
    end

    it 'returns not_found for unknown id' do
      result = client.swing(pendulum_id: 'no-such-id', force: 0.1)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end

    it 'swings multiple times and accumulates position' do
      client.swing(pendulum_id: pendulum_id, force: 0.3)
      result = client.swing(pendulum_id: pendulum_id, force: 0.3)
      expect(result[:current_position]).to be_within(0.001).of(0.6)
    end
  end

  describe '#damp_all' do
    it 'returns success' do
      result = client.damp_all
      expect(result[:success]).to be true
    end

    it 'reports number of damped pendulums' do
      client.create_pendulum(pole_pair: :focus_diffusion)
      client.create_pendulum(pole_pair: :analysis_intuition)
      result = client.damp_all
      expect(result[:damped]).to eq(2)
    end

    it 'reports zero when no pendulums exist' do
      result = client.damp_all
      expect(result[:damped]).to eq(0)
    end
  end

  describe '#check_resonance' do
    before { client.create_pendulum(pole_pair: :analysis_intuition, period: 10.0) }

    it 'returns success' do
      result = client.check_resonance(frequency: 0.1)
      expect(result[:success]).to be true
    end

    it 'detects resonance at natural frequency' do
      result = client.check_resonance(frequency: 0.1)
      expect(result[:count]).to eq(1)
    end

    it 'returns empty when no resonance' do
      result = client.check_resonance(frequency: 99.0)
      expect(result[:count]).to eq(0)
    end

    it 'returns error for non-positive frequency' do
      result = client.check_resonance(frequency: 0.0)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_frequency)
    end

    it 'returns resonant_pendulum_ids array' do
      result = client.check_resonance(frequency: 0.1)
      expect(result[:resonant_pendulum_ids]).to be_an(Array)
    end

    it 'echoes the frequency' do
      result = client.check_resonance(frequency: 0.1)
      expect(result[:frequency]).to eq(0.1)
    end
  end

  describe '#get_dominant_pole' do
    let(:pendulum_id) { client.create_pendulum(pole_pair: :certainty_doubt)[:pendulum_id] }

    it 'returns success for known pendulum' do
      result = client.get_dominant_pole(pendulum_id: pendulum_id)
      expect(result[:success]).to be true
    end

    it 'returns :neutral for centered pendulum' do
      result = client.get_dominant_pole(pendulum_id: pendulum_id)
      expect(result[:dominant_pole]).to eq(:neutral)
    end

    it 'returns the active pole after swinging' do
      client.swing(pendulum_id: pendulum_id, force: 0.8)
      result = client.get_dominant_pole(pendulum_id: pendulum_id)
      expect(result[:dominant_pole]).to eq(:doubt)
    end

    it 'returns not_found for unknown id' do
      result = client.get_dominant_pole(pendulum_id: 'ghost')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#most_active' do
    before do
      client.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.9)
      client.create_pendulum(pole_pair: :focus_diffusion, amplitude: 0.2)
      client.create_pendulum(pole_pair: :analysis_intuition, amplitude: 0.6)
    end

    it 'returns success' do
      expect(client.most_active[:success]).to be true
    end

    it 'returns pendulums sorted by descending amplitude' do
      result = client.most_active(limit: 3)
      amplitudes = result[:pendulums].map { |p| p[:amplitude] }
      expect(amplitudes).to eq(amplitudes.sort.reverse)
    end

    it 'respects limit' do
      result = client.most_active(limit: 2)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#most_damped' do
    before do
      client.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.1)
      client.create_pendulum(pole_pair: :focus_diffusion, amplitude: 0.7)
    end

    it 'returns success' do
      expect(client.most_damped[:success]).to be true
    end

    it 'returns pendulums sorted by ascending amplitude' do
      result = client.most_damped(limit: 2)
      amplitudes = result[:pendulums].map { |p| p[:amplitude] }
      expect(amplitudes).to eq(amplitudes.sort)
    end
  end

  describe '#pendulum_report' do
    before do
      client.create_pendulum(pole_pair: :certainty_doubt)
      client.create_pendulum(pole_pair: :focus_diffusion)
    end

    it 'returns success' do
      expect(client.pendulum_report[:success]).to be true
    end

    it 'includes a report hash' do
      result = client.pendulum_report
      expect(result[:report]).to be_a(Hash)
    end

    it 'report has total of 2' do
      expect(client.pendulum_report[:report][:total]).to eq(2)
    end
  end

  describe '#get_pendulum' do
    let(:pendulum_id) { client.create_pendulum(pole_pair: :approach_avoidance)[:pendulum_id] }

    it 'returns success with the pendulum hash' do
      result = client.get_pendulum(pendulum_id: pendulum_id)
      expect(result[:success]).to be true
      expect(result[:pendulum]).to be_a(Hash)
    end

    it 'returns not_found for unknown id' do
      result = client.get_pendulum(pendulum_id: 'fake-id')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end

    it 'pendulum hash includes pole_pair' do
      result = client.get_pendulum(pendulum_id: pendulum_id)
      expect(result[:pendulum][:pole_pair]).to eq(:approach_avoidance)
    end
  end
end
