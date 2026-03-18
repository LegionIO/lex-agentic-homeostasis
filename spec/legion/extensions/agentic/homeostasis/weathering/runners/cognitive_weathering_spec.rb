# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/weathering/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weathering::Runners::CognitiveWeathering do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Weathering::Client.new }

  describe '#apply_stressor' do
    it 'returns a hash with integrity' do
      result = client.apply_stressor(description: 'Heavy load', stressor_type: :cognitive_overload,
                                     intensity: 0.8, duration: 3600)
      expect(result).to have_key(:integrity)
    end

    it 'includes stressor details in result' do
      result = client.apply_stressor(description: 'Test stressor', stressor_type: :monotony,
                                     intensity: 0.3, duration: 1800)
      expect(result[:stressor][:description]).to eq('Test stressor')
    end

    it 'uses defaults when optional params omitted' do
      result = client.apply_stressor(description: 'minimal')
      expect(result).to have_key(:integrity)
    end

    it 'reduces integrity for high-intensity stressor' do
      client.apply_stressor(description: 'overload', intensity: 0.9, duration: 7200)
      status = client.integrity_status
      expect(status[:integrity]).to be < 1.0
    end

    it 'includes breaking flag' do
      result = client.apply_stressor(description: 'test', intensity: 0.5, duration: 3600)
      expect(result).to have_key(:breaking)
    end
  end

  describe '#recover' do
    before { client.apply_stressor(description: 'stress', intensity: 0.9, duration: 7200) }

    it 'increases integrity after recovery' do
      before = client.integrity_status[:integrity]
      client.recover(amount: 1.0)
      after = client.integrity_status[:integrity]
      expect(after).to be >= before
    end

    it 'returns a hash with integrity' do
      result = client.recover(amount: 1.0)
      expect(result).to have_key(:integrity)
    end

    it 'uses default amount of 1.0' do
      expect { client.recover }.not_to raise_error
    end
  end

  describe '#rest' do
    before { client.apply_stressor(description: 'stress', intensity: 0.9, duration: 7200) }

    it 'increases integrity' do
      before = client.integrity_status[:integrity]
      client.rest(amount: 1.0)
      after = client.integrity_status[:integrity]
      expect(after).to be >= before
    end

    it 'returns a hash with integrity' do
      result = client.rest(amount: 1.0)
      expect(result).to have_key(:integrity)
    end
  end

  describe '#weathering_report' do
    it 'returns a comprehensive report' do
      report = client.weathering_report
      expect(report).to have_key(:integrity)
      expect(report).to have_key(:integrity_label)
      expect(report).to have_key(:effective_capacity)
    end

    it 'reflects stressor history' do
      client.apply_stressor(description: 'first', intensity: 0.5, duration: 3600)
      report = client.weathering_report
      expect(report[:stressor_count]).to eq(1)
    end
  end

  describe '#integrity_status' do
    it 'returns all status keys' do
      status = client.integrity_status
      expect(status).to have_key(:integrity)
      expect(status).to have_key(:integrity_label)
      expect(status).to have_key(:tempering_level)
      expect(status).to have_key(:weathering_label)
      expect(status).to have_key(:effective_capacity)
      expect(status).to have_key(:fragile)
      expect(status).to have_key(:breaking)
    end

    it 'starts at pristine with full integrity' do
      status = client.integrity_status
      expect(status[:integrity_label]).to eq('pristine')
      expect(status[:integrity]).to eq(1.0)
    end
  end
end
