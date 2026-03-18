# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Surplus
          module Helpers
            class SurplusEngine
              include Constants

              attr_reader :committed, :reserved, :allocations

              def initialize
                @committed   = 0.0
                @reserved    = Constants::MIN_RESERVE
                @allocations = {}
              end

              def available_surplus
                used = @committed + @reserved + active_allocated
                Constants.clamp(Constants::TOTAL_CAPACITY - used).round(10)
              end

              def surplus_quality
                idle = Constants::TOTAL_CAPACITY - @committed
                raw = idle / Constants::TOTAL_CAPACITY
                Constants.clamp(raw).round(10)
              end

              def allocate!(activity_type:, amount:)
                return { allocated: false, reason: :invalid_type } unless Constants.valid_allocation_type?(activity_type)
                return { allocated: false, reason: :below_threshold } if available_surplus < Constants::SURPLUS_THRESHOLD

                clamped = Constants.clamp(amount, 0.0, available_surplus).round(10)
                return { allocated: false, reason: :insufficient_surplus } if clamped <= 0.0

                quality = surplus_quality
                allocation = Allocation.new(activity_type: activity_type, amount: clamped, quality: quality)
                @allocations[allocation.id] = allocation

                {
                  allocated:     true,
                  allocation_id: allocation.id,
                  amount:        clamped,
                  quality:       quality,
                  activity_type: activity_type
                }
              end

              def release!(allocation_id:)
                allocation = @allocations[allocation_id]
                return { released: false, reason: :not_found } unless allocation
                return { released: false, reason: :already_released } unless allocation.active?

                allocation.release!
                { released: true, allocation_id: allocation_id, amount: allocation.amount }
              end

              def commit!(amount:)
                clamped = Constants.clamp(amount.round(10), 0.0, Constants::TOTAL_CAPACITY - @reserved)
                @committed = Constants.clamp((@committed + clamped).round(10))
                { committed: @committed, available_surplus: available_surplus }
              end

              def uncommit!(amount:)
                clamped = Constants.clamp(amount.round(10), 0.0, @committed)
                @committed = Constants.clamp((@committed - clamped).round(10))
                { committed: @committed, available_surplus: available_surplus }
              end

              def replenish!
                old_committed = @committed
                @committed = Constants.clamp((@committed - Constants::REPLENISH_RATE).round(10))
                gained = (old_committed - @committed).round(10)
                { replenished: true, gained: gained, available_surplus: available_surplus }
              end

              def deplete!(amount:)
                delta = Constants.clamp(amount.round(10), 0.0, available_surplus)
                @committed = Constants.clamp((@committed + delta).round(10))
                { depleted: true, amount: delta, available_surplus: available_surplus }
              end

              def surplus_report
                surplus = available_surplus
                {
                  total_capacity:    Constants::TOTAL_CAPACITY,
                  committed:         @committed.round(10),
                  reserved:          @reserved.round(10),
                  active_allocated:  active_allocated.round(10),
                  available_surplus: surplus,
                  surplus_label:     Constants.surplus_label(surplus),
                  quality:           surplus_quality,
                  quality_label:     Constants.quality_label(surplus_quality),
                  allocation_count:  active_allocations.size
                }
              end

              def to_h
                surplus_report.merge(allocations: @allocations.transform_values(&:to_h))
              end

              private

              def active_allocations
                @allocations.values.select(&:active?)
              end

              def active_allocated
                active_allocations.sum(&:amount)
              end
            end
          end
        end
      end
    end
  end
end
