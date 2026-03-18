# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/temporal_discounting/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::DiscountingEngine do
  subject(:engine) { described_class.new }

  describe '#create_reward' do
    it 'creates and stores a reward' do
      reward = engine.create_reward(label: 'bonus', amount: 0.7, delay: 3.0)
      expect(reward).to be_a(Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::Reward)
      expect(engine.rewards).to have_key(reward.id)
    end

    it 'uses domain rate when no discount_rate given' do
      engine.set_domain_rate(domain: :financial, rate: 0.25)
      reward = engine.create_reward(label: 'fin', amount: 0.5, delay: 2.0, domain: :financial)
      expect(reward.discount_rate).to eq(0.25)
    end

    it 'uses explicit discount_rate over domain rate' do
      engine.set_domain_rate(domain: :financial, rate: 0.25)
      reward = engine.create_reward(label: 'fin', amount: 0.5, delay: 2.0, domain: :financial, discount_rate: 0.05)
      expect(reward.discount_rate).to eq(0.05)
    end
  end

  describe '#compare_rewards' do
    it 'returns preferred reward and delta' do
      a = engine.create_reward(label: 'a', amount: 0.9, delay: 1.0, discount_rate: 0.1)
      b = engine.create_reward(label: 'b', amount: 0.3, delay: 1.0, discount_rate: 0.1)
      result = engine.compare_rewards(reward_a_id: a.id, reward_b_id: b.id)
      expect(result[:preferred]).to eq(a.id)
      expect(result[:delta]).to be > 0
    end

    it 'returns tied when values are equal' do
      a = engine.create_reward(label: 'a', amount: 0.5, delay: 0.0, discount_rate: 0.1)
      b = engine.create_reward(label: 'b', amount: 0.5, delay: 0.0, discount_rate: 0.1)
      result = engine.compare_rewards(reward_a_id: a.id, reward_b_id: b.id)
      expect(result[:preferred]).to eq(:tied)
    end

    it 'returns error for missing reward' do
      a = engine.create_reward(label: 'a', amount: 0.5, delay: 1.0)
      result = engine.compare_rewards(reward_a_id: a.id, reward_b_id: 'missing')
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#worth_waiting_for?' do
    it 'returns true when subjective_value >= threshold' do
      r = engine.create_reward(label: 'x', amount: 0.9, delay: 0.5, discount_rate: 0.1)
      result = engine.worth_waiting_for?(reward_id: r.id, threshold: 0.3)
      expect(result[:worth_waiting]).to be true
    end

    it 'returns error for unknown reward' do
      result = engine.worth_waiting_for?(reward_id: 'nope')
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#set_domain_rate / #get_domain_rate' do
    it 'stores and retrieves domain rate' do
      engine.set_domain_rate(domain: :health, rate: 0.3)
      expect(engine.get_domain_rate(:health)).to eq(0.3)
    end

    it 'returns DEFAULT_DISCOUNT_RATE for unknown domain' do
      expect(engine.get_domain_rate(:unknown)).to eq(Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::DEFAULT_DISCOUNT_RATE)
    end

    it 'clamps domain rate to MAX' do
      engine.set_domain_rate(domain: :test, rate: 5.0)
      expect(engine.get_domain_rate(:test)).to eq(Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::MAX_DISCOUNT_RATE)
    end
  end

  describe '#immediate_vs_delayed' do
    it 'prefers immediate when immediate_amount > delayed discounted value' do
      result = engine.immediate_vs_delayed(immediate_amount: 0.8, delayed_amount: 0.9, delay: 100.0)
      expect(result[:preferred]).to eq(:immediate)
    end

    it 'prefers delayed when delayed discounted value > immediate' do
      result = engine.immediate_vs_delayed(immediate_amount: 0.1, delayed_amount: 0.9, delay: 0.1)
      expect(result[:preferred]).to eq(:delayed)
    end

    it 'uses domain rate in computation' do
      engine.set_domain_rate(domain: :social, rate: 0.5)
      result = engine.immediate_vs_delayed(immediate_amount: 0.4, delayed_amount: 0.9, delay: 2.0, domain: :social)
      expect(result[:discount_rate]).to eq(0.5)
    end

    it 'returns delta between values' do
      result = engine.immediate_vs_delayed(immediate_amount: 0.5, delayed_amount: 0.8, delay: 5.0)
      expect(result[:delta]).to be >= 0
    end
  end

  describe '#optimal_delay' do
    it 'computes maximum delay before value drops below threshold' do
      r = engine.create_reward(label: 'x', amount: 0.8, delay: 1.0, discount_rate: 0.1)
      result = engine.optimal_delay(reward_id: r.id, min_value: 0.4)
      # D = (A/V - 1) / k = (0.8/0.4 - 1) / 0.1 = 1/0.1 = 10
      expect(result[:max_delay]).to be_within(1e-9).of(10.0)
    end

    it 'returns error when reward not found' do
      result = engine.optimal_delay(reward_id: 'none')
      expect(result[:error]).to eq(:not_found)
    end

    it 'returns error when min_value > amount' do
      r = engine.create_reward(label: 'x', amount: 0.3, delay: 1.0)
      result = engine.optimal_delay(reward_id: r.id, min_value: 0.5)
      expect(result[:error]).to eq(:threshold_too_high)
    end
  end

  describe '#patience_report' do
    it 'returns empty report when no rewards' do
      report = engine.patience_report
      expect(report[:total_rewards]).to eq(0)
      expect(report[:avg_discount_rate]).to eq(0.0)
    end

    it 'computes avg discount rate and subjective value' do
      engine.create_reward(label: 'a', amount: 0.8, delay: 2.0, discount_rate: 0.1)
      engine.create_reward(label: 'b', amount: 0.6, delay: 2.0, discount_rate: 0.3)
      report = engine.patience_report
      expect(report[:total_rewards]).to eq(2)
      expect(report[:avg_discount_rate]).to be_within(1e-9).of(0.2)
      expect(report[:avg_subjective_value]).to be > 0
    end

    it 'includes impulsivity distribution' do
      engine.create_reward(label: 'a', amount: 0.8, delay: 1.0, discount_rate: 0.02)
      engine.create_reward(label: 'b', amount: 0.8, delay: 1.0, discount_rate: 0.5)
      report = engine.patience_report
      expect(report[:impulsivity_distribution]).to have_key(:patient)
      expect(report[:impulsivity_distribution]).to have_key(:very_impulsive)
    end
  end

  describe '#rewards_by_domain' do
    it 'filters rewards by domain' do
      engine.create_reward(label: 'fin', amount: 0.5, delay: 1.0, domain: :financial)
      engine.create_reward(label: 'hth', amount: 0.5, delay: 1.0, domain: :health)
      engine.create_reward(label: 'fin2', amount: 0.7, delay: 1.0, domain: :financial)
      result = engine.rewards_by_domain(domain: :financial)
      expect(result.size).to eq(2)
      expect(result.all? { |r| r.domain == :financial }).to be true
    end
  end

  describe '#most_valuable' do
    it 'returns top rewards by subjective_value' do
      engine.create_reward(label: 'low', amount: 0.1, delay: 100.0, discount_rate: 1.0)
      engine.create_reward(label: 'high', amount: 0.9, delay: 0.1, discount_rate: 0.01)
      result = engine.most_valuable(limit: 1)
      expect(result.first.label).to eq('high')
    end

    it 'limits the result set' do
      5.times { |i| engine.create_reward(label: "r#{i}", amount: 0.5, delay: i.to_f + 1.0) }
      expect(engine.most_valuable(limit: 3).size).to eq(3)
    end
  end

  describe '#prune_expired' do
    it 'removes rewards below min_value threshold' do
      engine.create_reward(label: 'dead', amount: 0.05, delay: 1000.0, discount_rate: 1.0)
      engine.create_reward(label: 'alive', amount: 0.9, delay: 0.1, discount_rate: 0.01)
      result = engine.prune_expired(min_value: 0.05)
      expect(result[:pruned]).to be >= 1
      expect(result[:remaining]).to be >= 1
    end
  end

  describe '#to_h' do
    it 'returns engine stats hash' do
      engine.create_reward(label: 'x', amount: 0.5, delay: 1.0)
      h = engine.to_h
      expect(h[:total_rewards]).to eq(1)
      expect(h[:domain_rates]).to be_a(Hash)
      expect(h[:patience]).to be_a(Hash)
    end
  end
end
