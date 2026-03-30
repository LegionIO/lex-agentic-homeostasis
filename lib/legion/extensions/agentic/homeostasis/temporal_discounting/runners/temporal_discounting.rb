# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module TemporalDiscounting
          module Runners
            module TemporalDiscounting
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def create_temporal_reward(label:, amount:, delay:, domain: :general, discount_rate: nil, **)
                reward = engine.create_reward(label: label, amount: amount, delay: delay,
                                              domain: domain, discount_rate: discount_rate)
                log.debug("[temporal_discounting] created reward id=#{reward.id[0..7]} " \
                          "sv=#{reward.subjective_value.round(4)} label=#{label}")
                { success: true, reward: reward.to_h }
              rescue StandardError => e
                log.warn("[temporal_discounting] create_temporal_reward failed: #{e.message}")
                { success: false, error: e.message }
              end

              def compare_temporal_rewards(reward_a_id:, reward_b_id:, **)
                result = engine.compare_rewards(reward_a_id: reward_a_id, reward_b_id: reward_b_id)
                log.debug("[temporal_discounting] compare preferred=#{result[:preferred]}")
                { success: !result.key?(:error), **result }
              rescue StandardError => e
                log.warn("[temporal_discounting] compare_temporal_rewards failed: #{e.message}")
                { success: false, error: e.message }
              end

              def check_worth_waiting(reward_id:, threshold: 0.3, **)
                result = engine.worth_waiting_for?(reward_id: reward_id, threshold: threshold)
                log.debug("[temporal_discounting] worth_waiting=#{result[:worth_waiting]} id=#{reward_id[0..7]}")
                { success: !result.key?(:error), **result }
              rescue StandardError => e
                log.warn("[temporal_discounting] check_worth_waiting failed: #{e.message}")
                { success: false, error: e.message }
              end

              def immediate_vs_delayed_comparison(immediate_amount:, delayed_amount:, delay:, domain: :general, **)
                result = engine.immediate_vs_delayed(
                  immediate_amount: immediate_amount,
                  delayed_amount:   delayed_amount,
                  delay:            delay,
                  domain:           domain
                )
                log.debug("[temporal_discounting] imm_vs_delayed preferred=#{result[:preferred]}")
                { success: true, **result }
              rescue StandardError => e
                log.warn("[temporal_discounting] immediate_vs_delayed_comparison failed: #{e.message}")
                { success: false, error: e.message }
              end

              def compute_optimal_delay(reward_id:, min_value: 0.5, **)
                result = engine.optimal_delay(reward_id: reward_id, min_value: min_value)
                log.debug("[temporal_discounting] optimal_delay=#{result[:max_delay]} id=#{reward_id[0..7]}")
                { success: !result.key?(:error), **result }
              rescue StandardError => e
                log.warn("[temporal_discounting] compute_optimal_delay failed: #{e.message}")
                { success: false, error: e.message }
              end

              def temporal_patience_report(**)
                report = engine.patience_report
                log.debug("[temporal_discounting] patience_report total=#{report[:total_rewards]}")
                { success: true, **report }
              rescue StandardError => e
                log.warn("[temporal_discounting] temporal_patience_report failed: #{e.message}")
                { success: false, error: e.message }
              end

              def set_domain_discount_rate(domain:, rate:, **)
                engine.set_domain_rate(domain: domain, rate: rate)
                log.debug("[temporal_discounting] set domain=#{domain} rate=#{rate}")
                { success: true, domain: domain, rate: engine.get_domain_rate(domain) }
              rescue StandardError => e
                log.warn("[temporal_discounting] set_domain_discount_rate failed: #{e.message}")
                { success: false, error: e.message }
              end

              def most_valuable_rewards(limit: 5, **)
                rewards = engine.most_valuable(limit: limit)
                log.debug("[temporal_discounting] most_valuable count=#{rewards.size}")
                { success: true, rewards: rewards.map(&:to_h), count: rewards.size }
              rescue StandardError => e
                log.warn("[temporal_discounting] most_valuable_rewards failed: #{e.message}")
                { success: false, error: e.message }
              end

              def update_temporal_discounting(min_value: 0.05, **)
                prune_result = engine.prune_expired(min_value: min_value)
                stats = engine.to_h
                log.debug("[temporal_discounting] update pruned=#{prune_result[:pruned]} " \
                          "remaining=#{prune_result[:remaining]}")
                { success: true, pruned: prune_result[:pruned], remaining: prune_result[:remaining], stats: stats }
              rescue StandardError => e
                log.warn("[temporal_discounting] update_temporal_discounting failed: #{e.message}")
                { success: false, error: e.message }
              end

              def temporal_discounting_stats(**)
                stats = engine.to_h
                log.debug("[temporal_discounting] stats total=#{stats[:total_rewards]}")
                { success: true, **stats }
              rescue StandardError => e
                log.warn("[temporal_discounting] temporal_discounting_stats failed: #{e.message}")
                { success: false, error: e.message }
              end

              private

              def engine
                @engine ||= Helpers::DiscountingEngine.new
              end
            end
          end
        end
      end
    end
  end
end
