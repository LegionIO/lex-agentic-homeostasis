# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tempo::Helpers::TempoRecord do
  let(:record) do
    described_class.new(
      domain:                 :analysis,
      baseline_tempo:         0.5,
      current_tempo:          0.6,
      task_tempo_requirement: 0.8
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(record.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores domain' do
      expect(record.domain).to eq(:analysis)
    end

    it 'clamps baseline_tempo to [0.0, 1.0]' do
      r = described_class.new(domain: :x, baseline_tempo: 1.5)
      expect(r.baseline_tempo).to eq(1.0)
    end

    it 'clamps current_tempo to [0.0, 1.0]' do
      r = described_class.new(domain: :x, current_tempo: -0.1)
      expect(r.current_tempo).to eq(0.0)
    end

    it 'clamps task_tempo_requirement to [0.0, 1.0]' do
      r = described_class.new(domain: :x, task_tempo_requirement: 2.0)
      expect(r.task_tempo_requirement).to eq(1.0)
    end

    it 'records created_at as utc time' do
      expect(record.created_at).to be_a(Time)
    end
  end

  describe '#mismatch' do
    it 'returns absolute difference between current and requirement' do
      expect(record.mismatch).to be_within(0.0000000001).of(0.2)
    end

    it 'is non-negative when current is below requirement' do
      r = described_class.new(domain: :x, current_tempo: 0.3, task_tempo_requirement: 0.7)
      expect(r.mismatch).to eq(0.4.round(10))
    end

    it 'is zero when synchronized' do
      r = described_class.new(domain: :x, current_tempo: 0.5, task_tempo_requirement: 0.5)
      expect(r.mismatch).to eq(0.0)
    end
  end

  describe '#accelerate!' do
    it 'increases current_tempo by default adjustment' do
      before = record.current_tempo
      record.accelerate!
      expect(record.current_tempo).to be_within(0.001).of(before + 0.05)
    end

    it 'accepts a custom amount' do
      before = record.current_tempo
      record.accelerate!(amount: 0.1)
      expect(record.current_tempo).to be_within(0.001).of(before + 0.1)
    end

    it 'clamps at 1.0' do
      r = described_class.new(domain: :x, current_tempo: 0.99)
      r.accelerate!(amount: 0.5)
      expect(r.current_tempo).to eq(1.0)
    end

    it 'returns self for chaining' do
      expect(record.accelerate!).to eq(record)
    end
  end

  describe '#decelerate!' do
    it 'decreases current_tempo by default adjustment' do
      before = record.current_tempo
      record.decelerate!
      expect(record.current_tempo).to be_within(0.001).of(before - 0.05)
    end

    it 'clamps at 0.0' do
      r = described_class.new(domain: :x, current_tempo: 0.01)
      r.decelerate!(amount: 0.5)
      expect(r.current_tempo).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(record.decelerate!).to eq(record)
    end
  end

  describe '#adapt_to!' do
    it 'moves current_tempo toward target by at most the rate' do
      r = described_class.new(domain: :x, current_tempo: 0.3)
      r.adapt_to!(target: 0.9, rate: 0.05)
      expect(r.current_tempo).to be_within(0.001).of(0.35)
    end

    it 'decelerates toward lower target' do
      r = described_class.new(domain: :x, current_tempo: 0.8)
      r.adapt_to!(target: 0.2, rate: 0.05)
      expect(r.current_tempo).to be_within(0.001).of(0.75)
    end

    it 'does not overshoot the target when already close' do
      r = described_class.new(domain: :x, current_tempo: 0.502)
      r.adapt_to!(target: 0.5, rate: 0.05)
      expect(r.current_tempo).to be_within(0.001).of(0.5)
    end

    it 'returns self for chaining' do
      expect(record.adapt_to!(target: 0.5)).to eq(record)
    end
  end

  describe '#tempo_label' do
    it 'returns :moderate for 0.5' do
      r = described_class.new(domain: :x, current_tempo: 0.5)
      expect(r.tempo_label).to eq(:moderate)
    end

    it 'returns :slow for 0.1' do
      r = described_class.new(domain: :x, current_tempo: 0.1)
      expect(r.tempo_label).to eq(:slow)
    end

    it 'returns :rapid for 0.95' do
      r = described_class.new(domain: :x, current_tempo: 0.95)
      expect(r.tempo_label).to eq(:rapid)
    end

    it 'returns :deliberate for 0.3' do
      r = described_class.new(domain: :x, current_tempo: 0.3)
      expect(r.tempo_label).to eq(:deliberate)
    end

    it 'returns :fast for 0.7' do
      r = described_class.new(domain: :x, current_tempo: 0.7)
      expect(r.tempo_label).to eq(:fast)
    end
  end

  describe '#mismatch_label' do
    it 'returns :synchronized for 0.05 mismatch' do
      r = described_class.new(domain: :x, current_tempo: 0.5, task_tempo_requirement: 0.55)
      expect(r.mismatch_label).to eq(:synchronized)
    end

    it 'returns :slightly_off for 0.15 mismatch' do
      r = described_class.new(domain: :x, current_tempo: 0.5, task_tempo_requirement: 0.65)
      expect(r.mismatch_label).to eq(:slightly_off)
    end

    it 'returns :mismatched for 0.35 mismatch' do
      r = described_class.new(domain: :x, current_tempo: 0.3, task_tempo_requirement: 0.65)
      expect(r.mismatch_label).to eq(:mismatched)
    end

    it 'returns :severely_mismatched for 0.6 mismatch' do
      r = described_class.new(domain: :x, current_tempo: 0.1, task_tempo_requirement: 0.7)
      expect(r.mismatch_label).to eq(:severely_mismatched)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = record.to_h
      expect(h).to include(
        :id, :domain, :baseline_tempo, :current_tempo,
        :task_tempo_requirement, :mismatch, :tempo_label,
        :mismatch_label, :created_at
      )
    end

    it 'rounds numeric values to 10 decimal places' do
      h = record.to_h
      expect(h[:current_tempo]).to eq(record.current_tempo.round(10))
    end
  end
end
