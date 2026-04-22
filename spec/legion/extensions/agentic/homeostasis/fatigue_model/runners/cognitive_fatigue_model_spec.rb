# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/fatigue_model/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FatigueModel::Runners::CognitiveFatigueModel do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::FatigueModel::Client.new }

  describe '#process_cognitive_task' do
    it 'depletes the specified channel and returns result' do
      result = client.process_cognitive_task(channel_name: :attention)
      expect(result).to have_key(:channel)
      expect(result).to have_key(:overall_fatigue)
      expect(result[:channel][:energy]).to be < 1.0
    end

    it 'tracks the correct channel' do
      result = client.process_cognitive_task(channel_name: :social)
      expect(result[:channel][:name]).to eq(:social)
    end

    it 'each channel depletes at its own rate' do
      r1 = client.process_cognitive_task(channel_name: :decision_making)
      r2 = client.process_cognitive_task(channel_name: :creative)
      expect(r1[:channel][:energy]).to be < r2[:channel][:energy]
    end
  end

  describe '#rest_cognitive_channel' do
    before { 5.times { client.process_cognitive_task(channel_name: :working_memory) } }

    it 'recovers the channel' do
      depleted = client.channel_fatigue_status(channel_name: :working_memory)[:energy]
      client.rest_cognitive_channel(channel_name: :working_memory)
      recovered = client.channel_fatigue_status(channel_name: :working_memory)[:energy]
      expect(recovered).to be > depleted
    end

    it 'returns the channel hash' do
      result = client.rest_cognitive_channel(channel_name: :working_memory)
      expect(result).to have_key(:channel)
    end
  end

  describe '#rest_all_channels' do
    before do
      %i[attention creative social].each do |ch|
        3.times { client.process_cognitive_task(channel_name: ch) }
      end
    end

    it 'recovers all channels and returns stats' do
      before_fatigue = client.overall_fatigue_report[:overall_fatigue]
      result = client.rest_all_channels
      expect(result[:overall_fatigue]).to be > before_fatigue
    end
  end

  describe '#channel_fatigue_status' do
    it 'returns channel status hash' do
      result = client.channel_fatigue_status(channel_name: :attention)
      expect(result).to include(name: :attention, energy: 1.0)
    end
  end

  describe '#overall_fatigue_report' do
    it 'returns overall_fatigue, most_fatigued, and channels_needing_rest' do
      result = client.overall_fatigue_report
      expect(result).to have_key(:overall_fatigue)
      expect(result).to have_key(:most_fatigued)
      expect(result).to have_key(:channels_needing_rest)
    end

    it 'returns 1.0 overall fatigue for fresh channels' do
      expect(client.overall_fatigue_report[:overall_fatigue]).to eq(1.0)
    end

    it 'reports decreased fatigue after depletion' do
      3.times { client.process_cognitive_task(channel_name: :decision_making) }
      expect(client.overall_fatigue_report[:overall_fatigue]).to be < 1.0
    end
  end

  describe '#fatigue_recommendations' do
    it 'returns delegate, rest, and any_action_needed keys' do
      result = client.fatigue_recommendations
      expect(result).to have_key(:delegate)
      expect(result).to have_key(:rest)
      expect(result).to have_key(:any_action_needed)
    end

    it 'returns false for any_action_needed when channels are fresh' do
      expect(client.fatigue_recommendations[:any_action_needed]).to be false
    end

    it 'returns true for any_action_needed when channels are low' do
      threshold = Legion::Extensions::Agentic::Homeostasis::FatigueModel::Helpers::Constants::REST_THRESHOLD
      steps = ((1.0 - threshold) / 0.06).ceil + 1
      steps.times { client.process_cognitive_task(channel_name: :decision_making) }
      expect(client.fatigue_recommendations[:any_action_needed]).to be true
    end
  end

  describe '#cognitive_quality_report' do
    it 'returns a quality hash keyed by channel names' do
      result = client.cognitive_quality_report
      expect(result).to have_key(:quality)
      expect(result[:quality]).to be_a(Hash)
      expect(result[:quality].keys).to match_array(
        Legion::Extensions::Agentic::Homeostasis::FatigueModel::Helpers::Constants::CHANNELS
      )
    end

    it 'shows degraded quality for depleted channels' do
      5.times { client.process_cognitive_task(channel_name: :attention) }
      report = client.cognitive_quality_report
      expect(report[:quality][:attention]).to be < 1.0
    end
  end

  describe '#update_cognitive_fatigue_model' do
    before do
      # Deplete decision_making past REST_THRESHOLD (0.3) — needs 12+ tasks at 0.06/task
      13.times { client.process_cognitive_task(channel_name: :decision_making) }
    end

    it 'rests depleted channels and returns stats' do
      before_fatigue = client.overall_fatigue_report[:overall_fatigue]
      result = client.update_cognitive_fatigue_model
      expect(result[:overall_fatigue]).to be > before_fatigue
    end

    it 'returns rested count and channels keys' do
      result = client.update_cognitive_fatigue_model
      expect(result).to have_key(:rested)
      expect(result).to have_key(:channels)
      expect(result[:rested]).to be >= 1
    end

    it 'only rests channels below REST_THRESHOLD' do
      result = client.update_cognitive_fatigue_model
      expect(result[:rested]).to be < Legion::Extensions::Agentic::Homeostasis::FatigueModel::Helpers::Constants::CHANNELS.size
    end
  end

  describe '#cognitive_fatigue_model_stats' do
    it 'returns full engine stats' do
      result = client.cognitive_fatigue_model_stats
      expect(result).to have_key(:channels)
      expect(result).to have_key(:overall_fatigue)
      expect(result).to have_key(:channel_count)
      expect(result[:channel_count]).to eq(5)
    end
  end
end
