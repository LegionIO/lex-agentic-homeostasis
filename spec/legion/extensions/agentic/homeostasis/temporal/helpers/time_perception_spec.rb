# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Temporal::Helpers::TimePerception do
  subject(:perception) { described_class.new }

  describe '#mark_event' do
    it 'records an event timestamp' do
      perception.mark_event(:deploy, domain: :ops)
      expect(perception.event_count(:deploy, domain: :ops)).to eq(1)
    end

    it 'records multiple events' do
      3.times { perception.mark_event(:deploy, domain: :ops) }
      expect(perception.event_count(:deploy, domain: :ops)).to eq(3)
    end
  end

  describe '#elapsed_since' do
    it 'returns nil for unknown event' do
      expect(perception.elapsed_since(:unknown)).to be_nil
    end

    it 'returns elapsed time' do
      perception.mark_event(:start)
      elapsed = perception.elapsed_since(:start)
      expect(elapsed).to be >= 0
    end
  end

  describe '#time_since_first' do
    it 'returns nil for unknown event' do
      expect(perception.time_since_first(:unknown)).to be_nil
    end

    it 'returns time since first occurrence' do
      perception.mark_event(:test)
      perception.mark_event(:test)
      expect(perception.time_since_first(:test)).to be >= 0
    end
  end

  describe '#set_deadline and #deadline_urgency' do
    it 'sets a deadline' do
      perception.set_deadline(:release, at: Time.now.utc + 3600)
      expect(perception.deadlines.size).to eq(1)
    end

    it 'returns urgency for upcoming deadline' do
      perception.set_deadline(:release, at: Time.now.utc + 3600)
      urgency = perception.deadline_urgency(:release)
      expect(Legion::Extensions::Agentic::Homeostasis::Temporal::Helpers::Constants::URGENCY_LEVELS + [:overdue]).to include(urgency)
    end

    it 'returns nil for unknown deadline' do
      expect(perception.deadline_urgency(:nonexistent)).to be_nil
    end

    it 'returns :overdue for past deadlines' do
      perception.set_deadline(:past, at: Time.now.utc - 10)
      expect(perception.deadline_urgency(:past)).to eq(:overdue)
    end
  end

  describe '#remove_deadline' do
    it 'removes a deadline' do
      perception.set_deadline(:test, at: Time.now.utc + 100)
      perception.remove_deadline(:test)
      expect(perception.deadlines).to be_empty
    end
  end

  describe '#overdue_deadlines' do
    it 'returns empty when no deadlines overdue' do
      perception.set_deadline(:future, at: Time.now.utc + 3600)
      expect(perception.overdue_deadlines).to be_empty
    end

    it 'lists overdue deadlines' do
      perception.set_deadline(:past, at: Time.now.utc - 60)
      overdue = perception.overdue_deadlines
      expect(overdue.size).to eq(1)
      expect(overdue.first[:id]).to eq(:past)
    end
  end

  describe '#upcoming_deadlines' do
    it 'lists deadlines within window' do
      perception.set_deadline(:soon, at: Time.now.utc + 600)
      perception.set_deadline(:far, at: Time.now.utc + 7200)
      upcoming = perception.upcoming_deadlines(within: 3600)
      expect(upcoming.size).to eq(1)
      expect(upcoming.first[:id]).to eq(:soon)
    end
  end

  describe '#update_subjective_time' do
    it 'returns subjective rate' do
      rate = perception.update_subjective_time(arousal: 0.5, cognitive_load: 0.5)
      expect(rate).to be_a(Numeric)
    end

    it 'increases rate with high arousal' do
      5.times { perception.update_subjective_time(arousal: 0.9, cognitive_load: 0.8) }
      expect(perception.subjective_rate).to be > 1.0
    end

    it 'decreases rate with low arousal' do
      5.times { perception.update_subjective_time(arousal: 0.1, cognitive_load: 0.1) }
      expect(perception.subjective_rate).to be < 1.0
    end
  end

  describe '#subjective_elapsed' do
    it 'scales real seconds by subjective rate' do
      perception.update_subjective_time(arousal: 0.9, cognitive_load: 0.9)
      result = perception.subjective_elapsed(10.0)
      expect(result).not_to eq(10.0)
    end
  end

  describe '#overall_urgency' do
    it 'returns :none with no deadlines' do
      expect(perception.overall_urgency).to eq(:none)
    end
  end

  describe '#to_h' do
    it 'returns complete state hash' do
      h = perception.to_h
      expect(h).to include(:event_domains, :active_deadlines, :overdue_count,
                           :subjective_rate, :overall_urgency, :tick_count)
    end
  end
end
