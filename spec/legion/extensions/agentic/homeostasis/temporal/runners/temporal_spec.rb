# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Temporal::Runners::Temporal do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Temporal::Client.new }

  describe '#mark_event' do
    it 'records and returns event info' do
      result = client.mark_event(event: :deploy, domain: :ops)
      expect(result[:marked]).to be true
      expect(result[:total_occurrences]).to eq(1)
    end
  end

  describe '#elapsed_since' do
    it 'returns elapsed for recorded event' do
      client.mark_event(event: :deploy, domain: :ops)
      result = client.elapsed_since(event: :deploy, domain: :ops)
      expect(result[:elapsed_seconds]).to be >= 0
      expect(result[:human]).to be_a(String)
    end

    it 'returns nil for unknown event' do
      result = client.elapsed_since(event: :unknown)
      expect(result[:elapsed_seconds]).to be_nil
      expect(result[:reason]).to eq(:no_record)
    end
  end

  describe '#set_deadline' do
    it 'sets a deadline' do
      result = client.set_deadline(id: :release, at: Time.now.utc + 3600)
      expect(result[:set]).to be true
    end
  end

  describe '#check_deadlines' do
    it 'returns deadline status' do
      client.set_deadline(id: :release, at: Time.now.utc + 600)
      result = client.check_deadlines
      expect(result).to include(:overdue, :upcoming, :urgency, :total)
      expect(result[:total]).to eq(1)
    end
  end

  describe '#update_time_perception' do
    it 'returns perception update' do
      result = client.update_time_perception(tick_results: {
                                               emotional_evaluation: { arousal: 0.8 },
                                               elapsed: 3.0, budget: 5.0
                                             })
      expect(result).to include(:subjective_rate, :interpretation, :overall_urgency)
    end

    it 'handles empty tick results' do
      result = client.update_time_perception(tick_results: {})
      expect(result[:subjective_rate]).to be_a(Numeric)
    end
  end

  describe '#predict_event' do
    it 'returns insufficient data for unknown events' do
      result = client.predict_event(event: :unknown)
      expect(result[:prediction]).to be_nil
      expect(result[:reason]).to eq(:insufficient_data)
    end
  end

  describe '#temporal_patterns' do
    it 'returns pattern info' do
      result = client.temporal_patterns
      expect(result).to include(:all, :periodic, :count)
    end
  end

  describe '#temporal_stats' do
    it 'returns summary stats' do
      result = client.temporal_stats
      expect(result).to include(:perception, :pattern_count, :overall_urgency)
    end
  end
end
