# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module TemporalDiscounting
          module Helpers
            class Reward
              attr_reader :id, :label, :amount, :delay, :domain, :discount_rate, :created_at

              def initialize(label:, amount:, delay:, domain: :general, discount_rate: DEFAULT_DISCOUNT_RATE)
                @id            = SecureRandom.uuid
                @label         = label
                @amount        = amount.clamp(0.0, 1.0)
                @delay         = delay.to_f
                @domain        = domain
                @discount_rate = discount_rate.clamp(MIN_DISCOUNT_RATE, MAX_DISCOUNT_RATE)
                @created_at    = Time.now.utc
              end

              def subjective_value
                (@amount / (1.0 + (@discount_rate * @delay))).round(10)
              end

              def value_ratio
                return 0.0 if @amount.zero?

                (subjective_value / @amount).round(10)
              end

              def value_label
                ratio = value_ratio
                VALUE_LABELS.each do |range, label|
                  return label if range.cover?(ratio)
                end
                :negligible
              end

              def impulsivity_label
                k = @discount_rate
                IMPULSIVITY_LABELS.each do |range, label|
                  return label if range.cover?(k)
                end
                :extreme
              end

              def worth_waiting?(threshold: 0.3)
                subjective_value >= threshold
              end

              def adjust_delay!(new_delay:)
                @delay = new_delay.to_f
              end

              def adjust_discount_rate!(new_rate:)
                @discount_rate = new_rate.clamp(MIN_DISCOUNT_RATE, MAX_DISCOUNT_RATE)
              end

              def to_h
                {
                  id:                @id,
                  label:             @label,
                  amount:            @amount,
                  delay:             @delay,
                  domain:            @domain,
                  discount_rate:     @discount_rate,
                  subjective_value:  subjective_value,
                  value_ratio:       value_ratio,
                  value_label:       value_label,
                  impulsivity_label: impulsivity_label,
                  worth_waiting:     worth_waiting?,
                  created_at:        @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
