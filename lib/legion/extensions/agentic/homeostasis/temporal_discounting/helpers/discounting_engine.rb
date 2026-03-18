# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module TemporalDiscounting
          module Helpers
            class DiscountingEngine
              attr_reader :rewards, :domain_rates

              def initialize
                @rewards      = {}
                @domain_rates = {}
              end

              def create_reward(label:, amount:, delay:, domain: :general, discount_rate: nil)
                rate = discount_rate || get_domain_rate(domain)
                reward = Reward.new(label: label, amount: amount, delay: delay, domain: domain, discount_rate: rate)
                @rewards[reward.id] = reward
                @rewards.shift while @rewards.size > MAX_REWARDS
                reward
              end

              def compare_rewards(reward_a_id:, reward_b_id:)
                a = @rewards.fetch(reward_a_id, nil)
                b = @rewards.fetch(reward_b_id, nil)
                return { error: :not_found, missing: missing_ids(reward_a_id, reward_b_id) } if a.nil? || b.nil?

                delta = (a.subjective_value - b.subjective_value).round(10)
                preferred = if delta.positive?
                              reward_a_id
                            elsif delta.negative?
                              reward_b_id
                            else
                              :tied
                            end

                {
                  preferred:      preferred,
                  delta:          delta.abs,
                  reward_a_value: a.subjective_value,
                  reward_b_value: b.subjective_value
                }
              end

              def worth_waiting_for?(reward_id:, threshold: 0.3)
                reward = @rewards.fetch(reward_id, nil)
                return { error: :not_found } if reward.nil?

                { reward_id: reward_id, worth_waiting: reward.worth_waiting?(threshold: threshold),
                  subjective_value: reward.subjective_value, threshold: threshold }
              end

              def set_domain_rate(domain:, rate:)
                @domain_rates[domain] = rate.clamp(MIN_DISCOUNT_RATE, MAX_DISCOUNT_RATE)
              end

              def get_domain_rate(domain)
                @domain_rates.fetch(domain, DEFAULT_DISCOUNT_RATE)
              end

              def immediate_vs_delayed(immediate_amount:, delayed_amount:, delay:, domain: :general)
                k = get_domain_rate(domain)
                delayed_sv = (delayed_amount / (1.0 + (k * delay.to_f))).round(10)
                immediate_sv = immediate_amount.to_f.clamp(0.0, 1.0).round(10)

                preferred = immediate_sv >= delayed_sv ? :immediate : :delayed

                {
                  preferred:       preferred,
                  immediate_value: immediate_sv,
                  delayed_value:   delayed_sv,
                  delta:           (immediate_sv - delayed_sv).abs.round(10),
                  discount_rate:   k
                }
              end

              def optimal_delay(reward_id:, min_value: 0.5)
                reward = @rewards.fetch(reward_id, nil)
                return { error: :not_found } if reward.nil?

                k = reward.discount_rate
                a = reward.amount
                return { error: :threshold_too_high } if min_value > a

                max_delay = ((a / min_value) - 1.0) / k
                {
                  reward_id:     reward_id,
                  max_delay:     max_delay.round(10),
                  min_value:     min_value,
                  amount:        a,
                  discount_rate: k
                }
              end

              def patience_report
                return empty_patience_report if @rewards.empty?

                values        = @rewards.values
                avg_rate      = (values.sum(&:discount_rate) / values.size).round(10)
                avg_sv        = (values.sum(&:subjective_value) / values.size).round(10)
                distribution  = build_impulsivity_distribution(values)

                {
                  total_rewards:            @rewards.size,
                  avg_discount_rate:        avg_rate,
                  avg_subjective_value:     avg_sv,
                  impulsivity_distribution: distribution
                }
              end

              def rewards_by_domain(domain:)
                @rewards.values.select { |r| r.domain == domain }
              end

              def most_valuable(limit: 5)
                @rewards.values
                        .sort_by { |r| -r.subjective_value }
                        .first(limit)
              end

              def prune_expired(min_value: 0.05)
                before = @rewards.size
                @rewards.reject! { |_, r| r.subjective_value < min_value }
                { pruned: before - @rewards.size, remaining: @rewards.size }
              end

              def to_h
                {
                  total_rewards: @rewards.size,
                  domain_rates:  @domain_rates,
                  patience:      patience_report
                }
              end

              private

              def missing_ids(id_a, id_b)
                missing = []
                missing << id_a unless @rewards.key?(id_a)
                missing << id_b unless @rewards.key?(id_b)
                missing
              end

              def empty_patience_report
                {
                  total_rewards:            0,
                  avg_discount_rate:        0.0,
                  avg_subjective_value:     0.0,
                  impulsivity_distribution: {}
                }
              end

              def build_impulsivity_distribution(values)
                distribution = Hash.new(0)
                values.each { |r| distribution[r.impulsivity_label] += 1 }
                distribution
              end
            end
          end
        end
      end
    end
  end
end
