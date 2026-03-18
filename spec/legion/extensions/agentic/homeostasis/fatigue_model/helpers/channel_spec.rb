# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FatigueModel::Helpers::Channel do
  subject(:channel) { described_class.new(name: :attention) }

  describe '#initialize' do
    it 'starts at full energy' do
      expect(channel.energy).to eq(1.0)
    end

    it 'starts with zero tasks_processed' do
      expect(channel.tasks_processed).to eq(0)
    end

    it 'starts with zero total_depletion' do
      expect(channel.total_depletion).to eq(0.0)
    end

    it 'stores the channel name' do
      expect(channel.name).to eq(:attention)
    end

    it 'sets created_at' do
      expect(channel.created_at).to be_a(Time)
    end

    it 'accepts custom energy' do
      ch = described_class.new(name: :social, energy: 0.5)
      expect(ch.energy).to eq(0.5)
    end

    it 'clamps initial energy above ceiling' do
      ch = described_class.new(name: :social, energy: 1.5)
      expect(ch.energy).to eq(1.0)
    end

    it 'clamps initial energy below floor' do
      ch = described_class.new(name: :social, energy: -0.1)
      expect(ch.energy).to eq(0.0)
    end
  end

  describe '#deplete!' do
    it 'reduces energy by the default depletion rate' do
      expect { channel.deplete! }.to change { channel.energy }.by(be_within(0.0001).of(-0.05))
    end

    it 'accepts a custom amount' do
      expect { channel.deplete!(amount: 0.2) }.to change { channel.energy }.by(be_within(0.0001).of(-0.2))
    end

    it 'increments tasks_processed' do
      expect { channel.deplete! }.to change { channel.tasks_processed }.by(1)
    end

    it 'accumulates total_depletion' do
      channel.deplete!
      channel.deplete!
      expect(channel.total_depletion).to be_within(0.001).of(0.10)
    end

    it 'sets last_used_at' do
      channel.deplete!
      expect(channel.last_used_at).to be_a(Time)
    end

    it 'floors energy at 0.0 when over-depleted' do
      ch = described_class.new(name: :attention, energy: 0.02)
      ch.deplete!
      expect(ch.energy).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(channel.deplete!).to be(channel)
    end
  end

  describe '#recover!' do
    before { channel.deplete!(amount: 0.3) }

    it 'increases energy by the default recovery rate' do
      expect { channel.recover! }.to change { channel.energy }.by(be_within(0.0001).of(0.08))
    end

    it 'accepts a custom amount' do
      expect { channel.recover!(amount: 0.1) }.to change { channel.energy }.by(be_within(0.0001).of(0.1))
    end

    it 'caps energy at 1.0' do
      channel.recover!(amount: 2.0)
      expect(channel.energy).to eq(1.0)
    end

    it 'returns self for chaining' do
      expect(channel.recover!).to be(channel)
    end
  end

  describe '#energy_label' do
    it 'returns :fresh when energy >= 0.8' do
      ch = described_class.new(name: :attention, energy: 0.9)
      expect(ch.energy_label).to eq(:fresh)
    end

    it 'returns :alert when energy is 0.7' do
      ch = described_class.new(name: :attention, energy: 0.7)
      expect(ch.energy_label).to eq(:alert)
    end

    it 'returns :tired when energy is 0.5' do
      ch = described_class.new(name: :attention, energy: 0.5)
      expect(ch.energy_label).to eq(:tired)
    end

    it 'returns :fatigued when energy is 0.25' do
      ch = described_class.new(name: :attention, energy: 0.25)
      expect(ch.energy_label).to eq(:fatigued)
    end

    it 'returns :exhausted when energy is 0.1' do
      ch = described_class.new(name: :attention, energy: 0.1)
      expect(ch.energy_label).to eq(:exhausted)
    end

    it 'returns :fresh at exactly 0.8' do
      ch = described_class.new(name: :attention, energy: 0.8)
      expect(ch.energy_label).to eq(:fresh)
    end
  end

  describe '#needs_rest?' do
    it 'returns false when energy is above threshold' do
      expect(channel.needs_rest?).to be false
    end

    it 'returns true when energy is below REST_THRESHOLD' do
      ch = described_class.new(name: :attention, energy: 0.2)
      expect(ch.needs_rest?).to be true
    end

    it 'returns false when energy equals REST_THRESHOLD exactly' do
      ch = described_class.new(name: :attention, energy: 0.3)
      expect(ch.needs_rest?).to be false
    end
  end

  describe '#needs_delegation?' do
    it 'returns false when energy is above threshold' do
      expect(channel.needs_delegation?).to be false
    end

    it 'returns true when energy is below DELEGATION_THRESHOLD' do
      ch = described_class.new(name: :attention, energy: 0.1)
      expect(ch.needs_delegation?).to be true
    end

    it 'returns false when energy equals DELEGATION_THRESHOLD exactly' do
      ch = described_class.new(name: :attention, energy: 0.2)
      expect(ch.needs_delegation?).to be false
    end
  end

  describe '#quality_modifier' do
    it 'returns full quality at full energy' do
      expect(channel.quality_modifier).to eq(1.0)
    end

    it 'returns reduced quality at half energy' do
      ch = described_class.new(name: :attention, energy: 0.5)
      expect(ch.quality_modifier).to eq(0.5)
    end

    it 'returns zero quality at zero energy' do
      ch = described_class.new(name: :attention, energy: 0.0)
      expect(ch.quality_modifier).to eq(0.0)
    end

    it 'degrades linearly with fatigue' do
      high = described_class.new(name: :attention, energy: 0.8)
      low  = described_class.new(name: :attention, energy: 0.4)
      expect(high.quality_modifier).to be > low.quality_modifier
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = channel.to_h
      expect(h.keys).to include(:name, :energy, :label, :tasks_processed, :total_depletion,
                                :needs_rest, :needs_delegation, :quality_modifier,
                                :last_used_at, :created_at)
    end

    it 'reflects current state' do
      channel.deplete!
      h = channel.to_h
      expect(h[:tasks_processed]).to eq(1)
      expect(h[:energy]).to be < 1.0
    end
  end
end
