# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Temporal::Helpers::TemporalStore do
  subject(:store) { described_class.new }

  describe '#record_event' do
    it 'records an event' do
      store.record_event(:deploy, domain: :ops)
      expect(store.perception.event_count(:deploy, domain: :ops)).to eq(1)
    end

    it 'updates patterns on repeated events' do
      5.times { store.record_event(:deploy, domain: :ops) }
      pattern = store.detect_patterns_for(:deploy, domain: :ops)
      expect(pattern).not_to be_nil
    end
  end

  describe '#elapsed' do
    it 'returns elapsed time for recorded event' do
      store.record_event(:start)
      expect(store.elapsed(:start)).to be >= 0
    end

    it 'returns nil for unknown event' do
      expect(store.elapsed(:unknown)).to be_nil
    end
  end

  describe '#predict_next' do
    it 'returns nil without enough data' do
      store.record_event(:test)
      expect(store.predict_next(:test)).to be_nil
    end
  end

  describe '#all_patterns' do
    it 'returns empty initially' do
      expect(store.all_patterns).to be_empty
    end
  end

  describe '#periodic_patterns' do
    it 'returns empty initially' do
      expect(store.periodic_patterns).to be_empty
    end
  end

  describe '#temporal_summary' do
    it 'returns summary hash' do
      summary = store.temporal_summary
      expect(summary).to include(:perception, :pattern_count, :periodic_count,
                                 :bursty_count, :overall_urgency, :overdue_deadlines)
    end
  end
end
