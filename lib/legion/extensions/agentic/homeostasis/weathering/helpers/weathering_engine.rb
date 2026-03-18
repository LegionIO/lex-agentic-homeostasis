# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weathering
          module Helpers
            class WeatheringEngine
              include Constants

              attr_reader :integrity, :tempering_level, :total_wear, :total_recovery

              def initialize
                @stressors      = []
                @events         = []
                @integrity      = Constants::DEFAULT_INTEGRITY
                @tempering_level = 0.0
                @total_wear     = 0.0
                @total_recovery = 0.0
              end

              def apply_stressor(stressor)
                prune_stressors
                @stressors << stressor

                record_event(:stressor_applied, stressor.to_h)
                wear!(stressor.cumulative_impact)
                temper!(stressor.cumulative_impact * Constants::TEMPERING_RATE) if stressor.manageable?

                to_h
              end

              def recover!(amount)
                amount = amount.clamp(0.0, 1.0)
                delta  = [amount * Constants::RECOVERY_RATE, 1.0 - @integrity].min
                @integrity      = (@integrity + delta).clamp(0.0, 1.0).round(10)
                @total_recovery = (@total_recovery + delta).round(10)
                record_event(:recovery, { amount: amount, delta: delta, integrity: @integrity })
                to_h
              end

              def rest!(amount = 1.0)
                amount = amount.clamp(0.0, 1.0)
                delta  = [amount * (Constants::RECOVERY_RATE * 5.0), 1.0 - @integrity].min
                @integrity      = (@integrity + delta).clamp(0.0, 1.0).round(10)
                @total_recovery = (@total_recovery + delta).round(10)
                record_event(:rest, { amount: amount, delta: delta, integrity: @integrity })
                to_h
              end

              def effective_capacity
                (@integrity * (1.0 + (@tempering_level * 0.2))).clamp(0.0, 1.2).round(10)
              end

              def fragile?
                @integrity <= Constants::CRITICAL_INTEGRITY
              end

              def breaking?
                @integrity <= Constants::BREAKDOWN_INTEGRITY
              end

              def stressor_count
                @stressors.size
              end

              def weathering_report
                {
                  integrity:          @integrity.round(10),
                  integrity_label:    Constants.integrity_label(@integrity),
                  tempering_level:    @tempering_level.round(10),
                  weathering_label:   Constants.weathering_label(@tempering_level),
                  effective_capacity: effective_capacity,
                  total_wear:         @total_wear.round(10),
                  total_recovery:     @total_recovery.round(10),
                  stressor_count:     @stressors.size,
                  fragile:            fragile?,
                  breaking:           breaking?,
                  recent_stressors:   @stressors.last(5).map(&:to_h)
                }
              end

              def to_h
                {
                  integrity:          @integrity.round(10),
                  tempering_level:    @tempering_level.round(10),
                  effective_capacity: effective_capacity,
                  fragile:            fragile?,
                  breaking:           breaking?
                }
              end

              private

              def wear!(amount)
                delta = (amount * Constants::WEAR_RATE).clamp(0.0, @integrity)
                @integrity      = (@integrity - delta).clamp(0.0, 1.0).round(10)
                @total_wear     = (@total_wear + delta).round(10)
              end

              def temper!(amount)
                delta            = amount.clamp(0.0, 1.0 - @tempering_level)
                @tempering_level = (@tempering_level + delta).clamp(0.0, 1.0).round(10)
              end

              def record_event(type, data)
                prune_events
                @events << { type: type, data: data, timestamp: Time.now.utc.iso8601 }
              end

              def prune_stressors
                @stressors.shift while @stressors.size >= Constants::MAX_STRESSORS
              end

              def prune_events
                @events.shift while @events.size >= Constants::MAX_EVENTS
              end
            end
          end
        end
      end
    end
  end
end
