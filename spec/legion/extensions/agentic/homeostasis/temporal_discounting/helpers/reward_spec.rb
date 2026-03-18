# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/temporal_discounting/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::Reward do
  subject(:reward) do
    described_class.new(label: 'test', amount: 0.8, delay: 5.0, domain: :financial, discount_rate: 0.1)
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(reward.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores the label' do
      expect(reward.label).to eq('test')
    end

    it 'clamps amount to [0, 1]' do
      r = described_class.new(label: 'x', amount: 1.5, delay: 1.0)
      expect(r.amount).to eq(1.0)
    end

    it 'clamps amount below 0 to 0' do
      r = described_class.new(label: 'x', amount: -0.5, delay: 1.0)
      expect(r.amount).to eq(0.0)
    end

    it 'clamps discount_rate to MIN' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 1.0, discount_rate: 0.0)
      expect(r.discount_rate).to eq(Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::MIN_DISCOUNT_RATE)
    end

    it 'clamps discount_rate to MAX' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 1.0, discount_rate: 2.0)
      expect(r.discount_rate).to eq(Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::MAX_DISCOUNT_RATE)
    end

    it 'records created_at' do
      expect(reward.created_at).to be_a(Time)
    end
  end

  describe '#subjective_value' do
    it 'computes hyperbolic discount formula V = A / (1 + k*D)' do
      # A=0.8, k=0.1, D=5.0 => 0.8 / (1 + 0.5) = 0.8 / 1.5
      expected = 0.8 / (1.0 + (0.1 * 5.0))
      expect(reward.subjective_value).to be_within(1e-9).of(expected)
    end

    it 'equals amount when delay is 0' do
      r = described_class.new(label: 'x', amount: 0.6, delay: 0.0)
      expect(r.subjective_value).to be_within(1e-9).of(0.6)
    end

    it 'approaches zero as delay grows large' do
      r = described_class.new(label: 'x', amount: 1.0, delay: 10_000.0, discount_rate: 1.0)
      expect(r.subjective_value).to be < 0.001
    end

    it 'is lower with higher discount rate' do
      r_low  = described_class.new(label: 'x', amount: 0.9, delay: 10.0, discount_rate: 0.05)
      r_high = described_class.new(label: 'x', amount: 0.9, delay: 10.0, discount_rate: 0.5)
      expect(r_low.subjective_value).to be > r_high.subjective_value
    end
  end

  describe '#value_ratio' do
    it 'returns subjective_value / amount' do
      expected = reward.subjective_value / reward.amount
      expect(reward.value_ratio).to be_within(1e-9).of(expected)
    end

    it 'returns 0.0 when amount is 0' do
      r = described_class.new(label: 'x', amount: 0.0, delay: 1.0)
      expect(r.value_ratio).to eq(0.0)
    end

    it 'is 1.0 when delay is 0' do
      r = described_class.new(label: 'x', amount: 0.7, delay: 0.0)
      expect(r.value_ratio).to be_within(1e-9).of(1.0)
    end
  end

  describe '#value_label' do
    it 'returns :full_value when ratio >= 0.8' do
      r = described_class.new(label: 'x', amount: 0.9, delay: 0.0)
      expect(r.value_label).to eq(:full_value)
    end

    it 'returns :negligible when ratio < 0.2' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 100.0, discount_rate: 1.0)
      expect(r.value_label).to eq(:negligible)
    end

    it 'returns :moderate_value for mid-range ratio' do
      # A=0.5, k=0.1, D=10 => sv = 0.5/2 = 0.25, ratio = 0.5 => moderate_value
      r = described_class.new(label: 'x', amount: 0.5, delay: 10.0, discount_rate: 0.1)
      ratio = r.value_ratio
      expect(ratio).to be_between(0.4, 0.6)
      expect(r.value_label).to eq(:moderate_value)
    end
  end

  describe '#impulsivity_label' do
    it 'returns :patient for k < 0.05' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 1.0, discount_rate: 0.02)
      expect(r.impulsivity_label).to eq(:patient)
    end

    it 'returns :moderate for k in [0.05, 0.15)' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 1.0, discount_rate: 0.1)
      expect(r.impulsivity_label).to eq(:moderate)
    end

    it 'returns :impulsive for k in [0.15, 0.3)' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 1.0, discount_rate: 0.2)
      expect(r.impulsivity_label).to eq(:impulsive)
    end

    it 'returns :very_impulsive for k in [0.3, 0.6)' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 1.0, discount_rate: 0.4)
      expect(r.impulsivity_label).to eq(:very_impulsive)
    end

    it 'returns :extreme for k in [0.6, 1.0]' do
      r = described_class.new(label: 'x', amount: 0.5, delay: 1.0, discount_rate: 0.8)
      expect(r.impulsivity_label).to eq(:extreme)
    end
  end

  describe '#worth_waiting?' do
    it 'returns true when subjective_value >= default threshold 0.3' do
      r = described_class.new(label: 'x', amount: 0.9, delay: 0.5, discount_rate: 0.1)
      expect(r.worth_waiting?).to be true
    end

    it 'returns false when subjective_value < threshold' do
      r = described_class.new(label: 'x', amount: 0.1, delay: 100.0, discount_rate: 1.0)
      expect(r.worth_waiting?).to be false
    end

    it 'accepts custom threshold' do
      r = described_class.new(label: 'x', amount: 0.8, delay: 2.0, discount_rate: 0.1)
      sv = r.subjective_value
      expect(r.worth_waiting?(threshold: sv - 0.01)).to be true
      expect(r.worth_waiting?(threshold: sv + 0.01)).to be false
    end
  end

  describe '#adjust_delay!' do
    it 'updates delay and changes subjective_value' do
      original_sv = reward.subjective_value
      reward.adjust_delay!(new_delay: 50.0)
      expect(reward.delay).to eq(50.0)
      expect(reward.subjective_value).to be < original_sv
    end
  end

  describe '#adjust_discount_rate!' do
    it 'updates discount_rate clamped to [MIN, MAX]' do
      reward.adjust_discount_rate!(new_rate: 0.5)
      expect(reward.discount_rate).to eq(0.5)
    end

    it 'clamps below MIN_DISCOUNT_RATE' do
      reward.adjust_discount_rate!(new_rate: 0.0)
      expect(reward.discount_rate).to eq(Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::MIN_DISCOUNT_RATE)
    end
  end

  describe '#to_h' do
    it 'returns a complete hash' do
      h = reward.to_h
      expect(h[:id]).to eq(reward.id)
      expect(h[:label]).to eq('test')
      expect(h[:amount]).to eq(0.8)
      expect(h[:delay]).to eq(5.0)
      expect(h[:domain]).to eq(:financial)
      expect(h[:discount_rate]).to eq(0.1)
      expect(h[:subjective_value]).to be_a(Float)
      expect(h[:value_ratio]).to be_a(Float)
      expect(h[:value_label]).to be_a(Symbol)
      expect(h[:impulsivity_label]).to be_a(Symbol)
      expect(h[:worth_waiting]).to be(true).or be(false)
      expect(h[:created_at]).to be_a(Time)
    end
  end
end
