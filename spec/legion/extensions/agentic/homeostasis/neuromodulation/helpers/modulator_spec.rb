# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Helpers::Modulator do
  subject(:mod) { described_class.new(:dopamine) }

  describe '#initialize' do
    it 'sets name' do
      expect(mod.name).to eq(:dopamine)
    end

    it 'sets level to DEFAULT_LEVEL' do
      expect(mod.level).to eq(0.5)
    end

    it 'sets baseline to DEFAULT_LEVEL' do
      expect(mod.baseline).to eq(0.5)
    end

    it 'starts with empty events' do
      expect(mod.events).to be_empty
    end
  end

  describe '#boost' do
    it 'increases level' do
      mod.boost(0.2)
      expect(mod.level).to be_within(0.001).of(0.7)
    end

    it 'clamps at LEVEL_CEILING' do
      mod.boost(1.0)
      expect(mod.level).to eq(1.0)
    end

    it 'records an event' do
      mod.boost(0.1, reason: :reward)
      expect(mod.events.size).to eq(1)
      expect(mod.events.last[:type]).to eq(:boost)
      expect(mod.events.last[:reason]).to eq(:reward)
    end

    it 'returns the new level' do
      result = mod.boost(0.1)
      expect(result).to be_within(0.001).of(0.6)
    end
  end

  describe '#suppress' do
    it 'decreases level' do
      mod.suppress(0.2)
      expect(mod.level).to be_within(0.001).of(0.3)
    end

    it 'clamps at LEVEL_FLOOR' do
      mod.suppress(1.0)
      expect(mod.level).to eq(0.0)
    end

    it 'records an event' do
      mod.suppress(0.1, reason: :fatigue)
      expect(mod.events.size).to eq(1)
      expect(mod.events.last[:type]).to eq(:suppress)
      expect(mod.events.last[:reason]).to eq(:fatigue)
    end

    it 'returns the new level' do
      result = mod.suppress(0.1)
      expect(result).to be_within(0.001).of(0.4)
    end
  end

  describe '#drift_to_baseline' do
    it 'moves level toward baseline' do
      mod.boost(0.3)
      level_before = mod.level
      mod.drift_to_baseline
      expect(mod.level).to be < level_before
    end

    it 'does not overshoot baseline' do
      mod.boost(0.3)
      100.times { mod.drift_to_baseline }
      expect(mod.level).to be >= mod.baseline
    end
  end

  describe '#optimal?' do
    it 'returns true when level is in optimal range' do
      expect(mod.optimal?).to be true
    end

    it 'returns false when level is too high' do
      mod.boost(0.5)
      expect(mod.optimal?).to be false
    end

    it 'returns false when level is too low' do
      mod.suppress(0.4)
      expect(mod.optimal?).to be false
    end
  end

  describe '#state_label' do
    it 'returns :optimal at default level' do
      expect(mod.state_label).to eq(:optimal)
    end

    it 'returns :surplus when high' do
      mod.boost(0.4)
      expect(mod.state_label).to eq(:surplus)
    end

    it 'returns :deficit when low' do
      mod.suppress(0.4)
      expect(mod.state_label).to eq(:deficit)
    end
  end

  describe '#influence_on' do
    it 'returns a numeric influence for known property' do
      expect(mod.influence_on(:learning_rate)).to be_a(Numeric)
    end

    it 'returns 0.0 for unknown property' do
      expect(mod.influence_on(:unknown_property)).to eq(0.0)
    end

    it 'returns higher influence when level is high' do
      mod.boost(0.3)
      high_influence = mod.influence_on(:learning_rate)
      mod2 = described_class.new(:dopamine)
      mod2.suppress(0.3)
      low_influence = mod2.influence_on(:learning_rate)
      expect(high_influence).to be > low_influence
    end
  end

  describe '#to_h' do
    it 'returns a hash with required keys' do
      h = mod.to_h
      expect(h).to have_key(:name)
      expect(h).to have_key(:level)
      expect(h).to have_key(:baseline)
      expect(h).to have_key(:state)
      expect(h).to have_key(:optimal)
      expect(h).to have_key(:event_count)
    end

    it 'reflects current state' do
      mod.boost(0.3)
      h = mod.to_h
      expect(h[:level]).to be > 0.5
      expect(h[:event_count]).to eq(1)
    end
  end

  describe 'event ring buffer' do
    it 'caps events at MAX_EVENTS' do
      250.times { mod.boost(0.001) }
      expect(mod.events.size).to eq(200)
    end
  end
end
