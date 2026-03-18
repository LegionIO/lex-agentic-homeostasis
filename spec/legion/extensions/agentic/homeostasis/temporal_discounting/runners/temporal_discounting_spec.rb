# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/temporal_discounting/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Runners::TemporalDiscounting do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Client.new }

  describe '#create_temporal_reward' do
    it 'creates a reward and returns success' do
      result = client.create_temporal_reward(label: 'test', amount: 0.7, delay: 5.0)
      expect(result[:success]).to be true
      expect(result[:reward][:id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:reward][:label]).to eq('test')
    end

    it 'stores the reward in the engine' do
      result = client.create_temporal_reward(label: 'x', amount: 0.5, delay: 2.0)
      id = result[:reward][:id]
      expect(client.engine.rewards).to have_key(id)
    end

    it 'passes domain and discount_rate through' do
      result = client.create_temporal_reward(
        label: 'fin', amount: 0.8, delay: 10.0, domain: :financial, discount_rate: 0.25
      )
      expect(result[:reward][:domain]).to eq(:financial)
      expect(result[:reward][:discount_rate]).to eq(0.25)
    end
  end

  describe '#compare_temporal_rewards' do
    it 'compares two rewards' do
      a = client.create_temporal_reward(label: 'a', amount: 0.9, delay: 1.0, discount_rate: 0.1)
      b = client.create_temporal_reward(label: 'b', amount: 0.2, delay: 1.0, discount_rate: 0.1)
      result = client.compare_temporal_rewards(reward_a_id: a[:reward][:id], reward_b_id: b[:reward][:id])
      expect(result[:success]).to be true
      expect(result[:preferred]).to eq(a[:reward][:id])
    end

    it 'returns not_found error for missing reward' do
      r = client.create_temporal_reward(label: 'x', amount: 0.5, delay: 1.0)
      result = client.compare_temporal_rewards(reward_a_id: r[:reward][:id], reward_b_id: 'missing')
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#check_worth_waiting' do
    it 'returns worth_waiting true for high-value reward' do
      r = client.create_temporal_reward(label: 'x', amount: 0.9, delay: 0.5, discount_rate: 0.1)
      result = client.check_worth_waiting(reward_id: r[:reward][:id])
      expect(result[:success]).to be true
      expect(result[:worth_waiting]).to be true
    end

    it 'returns not_found error for missing id' do
      result = client.check_worth_waiting(reward_id: 'missing')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#immediate_vs_delayed_comparison' do
    it 'returns preferred option' do
      result = client.immediate_vs_delayed_comparison(
        immediate_amount: 0.8, delayed_amount: 0.9, delay: 100.0
      )
      expect(result[:success]).to be true
      expect(result[:preferred]).to be_a(Symbol)
    end

    it 'includes discount_rate in result' do
      result = client.immediate_vs_delayed_comparison(
        immediate_amount: 0.3, delayed_amount: 0.9, delay: 5.0
      )
      expect(result[:discount_rate]).to be_a(Float)
    end
  end

  describe '#compute_optimal_delay' do
    it 'returns max_delay for a given min_value' do
      r = client.create_temporal_reward(label: 'x', amount: 0.8, delay: 1.0, discount_rate: 0.1)
      result = client.compute_optimal_delay(reward_id: r[:reward][:id], min_value: 0.4)
      expect(result[:success]).to be true
      expect(result[:max_delay]).to be_within(1e-9).of(10.0)
    end

    it 'returns not_found for missing reward' do
      result = client.compute_optimal_delay(reward_id: 'none')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#temporal_patience_report' do
    it 'returns report with success' do
      client.create_temporal_reward(label: 'a', amount: 0.8, delay: 2.0, discount_rate: 0.1)
      result = client.temporal_patience_report
      expect(result[:success]).to be true
      expect(result[:total_rewards]).to eq(1)
      expect(result[:avg_discount_rate]).to be_a(Float)
    end
  end

  describe '#set_domain_discount_rate' do
    it 'sets and confirms domain rate' do
      result = client.set_domain_discount_rate(domain: :health, rate: 0.2)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:health)
      expect(result[:rate]).to eq(0.2)
    end
  end

  describe '#most_valuable_rewards' do
    it 'returns top rewards by subjective_value' do
      client.create_temporal_reward(label: 'low', amount: 0.1, delay: 100.0, discount_rate: 1.0)
      client.create_temporal_reward(label: 'high', amount: 0.9, delay: 0.0, discount_rate: 0.1)
      result = client.most_valuable_rewards(limit: 1)
      expect(result[:success]).to be true
      expect(result[:rewards].first[:label]).to eq('high')
      expect(result[:count]).to eq(1)
    end
  end

  describe '#update_temporal_discounting' do
    it 'prunes low-value rewards and returns stats' do
      client.create_temporal_reward(label: 'dead', amount: 0.02, delay: 1000.0, discount_rate: 1.0)
      client.create_temporal_reward(label: 'alive', amount: 0.9, delay: 0.1, discount_rate: 0.01)
      result = client.update_temporal_discounting(min_value: 0.05)
      expect(result[:success]).to be true
      expect(result[:pruned]).to be >= 1
      expect(result[:stats]).to be_a(Hash)
    end
  end

  describe '#temporal_discounting_stats' do
    it 'returns engine stats' do
      client.create_temporal_reward(label: 'x', amount: 0.5, delay: 1.0)
      result = client.temporal_discounting_stats
      expect(result[:success]).to be true
      expect(result[:total_rewards]).to eq(1)
    end
  end
end
