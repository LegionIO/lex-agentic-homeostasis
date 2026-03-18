# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Helpers::ModulatorSystem do
  subject(:system) { described_class.new }

  describe '#initialize' do
    it 'creates all four modulators' do
      expect(system.modulators.keys).to contain_exactly(:dopamine, :serotonin, :norepinephrine, :acetylcholine)
    end

    it 'starts each at default level' do
      system.modulators.each_value do |mod|
        expect(mod.level).to eq(0.5)
      end
    end
  end

  describe '#boost' do
    it 'raises for unknown modulator' do
      expect { system.boost(:cortisol, 0.1) }.to raise_error(ArgumentError)
    end

    it 'increases the target modulator level' do
      system.boost(:dopamine, 0.2)
      expect(system.level(:dopamine)).to be_within(0.001).of(0.7)
    end

    it 'applies dopamine->serotonin suppression when dopamine goes high' do
      serotonin_before = system.level(:serotonin)
      system.boost(:dopamine, 0.3)
      expect(system.level(:serotonin)).to be < serotonin_before
    end

    it 'does not suppress serotonin for moderate dopamine boost' do
      serotonin_before = system.level(:serotonin)
      system.boost(:dopamine, 0.05)
      expect(system.level(:serotonin)).to eq(serotonin_before)
    end
  end

  describe '#suppress' do
    it 'raises for unknown modulator' do
      expect { system.suppress(:cortisol, 0.1) }.to raise_error(ArgumentError)
    end

    it 'decreases the target modulator level' do
      system.suppress(:serotonin, 0.2)
      expect(system.level(:serotonin)).to be_within(0.001).of(0.3)
    end

    it 'applies norepinephrine->acetylcholine suppression when NE goes very high' do
      ach_before = system.level(:acetylcholine)
      system.boost(:norepinephrine, 0.35)
      expect(system.level(:acetylcholine)).to be < ach_before
    end
  end

  describe '#level' do
    it 'raises for unknown modulator' do
      expect { system.level(:unknown) }.to raise_error(ArgumentError)
    end

    it 'returns current level' do
      expect(system.level(:dopamine)).to eq(0.5)
    end
  end

  describe '#all_levels' do
    it 'returns a hash with all four modulators' do
      levels = system.all_levels
      expect(levels.keys).to contain_exactly(:dopamine, :serotonin, :norepinephrine, :acetylcholine)
    end

    it 'reflects current state' do
      system.boost(:dopamine, 0.2)
      levels = system.all_levels
      expect(levels[:dopamine]).to be > 0.5
    end
  end

  describe '#tick' do
    it 'drifts all modulators toward baseline' do
      system.boost(:dopamine, 0.3)
      level_before = system.level(:dopamine)
      system.tick
      expect(system.level(:dopamine)).to be < level_before
    end

    it 'processes all four modulators' do
      system.boost(:norepinephrine, 0.2)
      system.suppress(:serotonin, 0.2)
      ne_before   = system.level(:norepinephrine)
      ser_before  = system.level(:serotonin)
      system.tick
      expect(system.level(:norepinephrine)).to be < ne_before
      expect(system.level(:serotonin)).to be > ser_before
    end
  end

  describe 'composite influences' do
    describe '#learning_rate_modifier' do
      it 'returns a value between 0 and 1' do
        expect(system.learning_rate_modifier).to be_between(0.0, 1.0)
      end

      it 'increases with higher dopamine' do
        base = system.learning_rate_modifier
        system.boost(:dopamine, 0.2)
        expect(system.learning_rate_modifier).to be > base
      end
    end

    describe '#attention_precision' do
      it 'returns a value between 0 and 1' do
        expect(system.attention_precision).to be_between(0.0, 1.0)
      end

      it 'increases with higher norepinephrine' do
        base = system.attention_precision
        system.boost(:norepinephrine, 0.1)
        expect(system.attention_precision).to be > base
      end
    end

    describe '#exploration_bias' do
      it 'equals dopamine level' do
        expect(system.exploration_bias).to eq(system.level(:dopamine))
      end
    end

    describe '#patience_factor' do
      it 'equals serotonin level' do
        expect(system.patience_factor).to eq(system.level(:serotonin))
      end
    end

    describe '#memory_encoding_strength' do
      it 'equals acetylcholine level' do
        expect(system.memory_encoding_strength).to eq(system.level(:acetylcholine))
      end
    end

    describe '#arousal_level' do
      it 'equals norepinephrine level' do
        expect(system.arousal_level).to eq(system.level(:norepinephrine))
      end
    end

    describe '#composite_influences' do
      it 'returns a hash with all influence keys' do
        ci = system.composite_influences
        expect(ci).to have_key(:learning_rate_modifier)
        expect(ci).to have_key(:attention_precision)
        expect(ci).to have_key(:exploration_bias)
        expect(ci).to have_key(:patience_factor)
        expect(ci).to have_key(:memory_encoding_strength)
        expect(ci).to have_key(:arousal_level)
      end
    end
  end

  describe '#balance_score' do
    it 'returns 1.0 when all modulators are optimal' do
      expect(system.balance_score).to eq(1.0)
    end

    it 'decreases when a modulator goes out of range' do
      system.boost(:dopamine, 0.5)
      expect(system.balance_score).to be < 1.0
    end
  end

  describe '#to_h' do
    it 'returns modulators, influences, and balance' do
      h = system.to_h
      expect(h).to have_key(:modulators)
      expect(h).to have_key(:influences)
      expect(h).to have_key(:balance)
    end
  end
end
