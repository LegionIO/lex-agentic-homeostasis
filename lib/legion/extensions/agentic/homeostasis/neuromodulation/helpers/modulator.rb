# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Neuromodulation
          module Helpers
            class Modulator
              include Constants

              attr_reader :name, :level, :baseline, :events

              def initialize(name)
                @name     = name
                @level    = DEFAULT_LEVEL
                @baseline = DEFAULT_LEVEL
                @events   = []
              end

              def boost(amount, reason: nil)
                old_level = @level
                @level    = clamp(@level + amount)
                record_event(:boost, amount, reason, old_level)
                @level
              end

              def suppress(amount, reason: nil)
                old_level = @level
                @level    = clamp(@level - amount)
                record_event(:suppress, amount, reason, old_level)
                @level
              end

              def drift_to_baseline
                delta  = @baseline - @level
                @level = clamp(@level + (delta * BASELINE_DRIFT))
              end

              def optimal?
                OPTIMAL_RANGES.fetch(@name).include?(@level)
              end

              def state_label
                range = OPTIMAL_RANGES.fetch(@name)
                if @level > range.end
                  STATE_LABELS.dig(@name, :high)
                elsif @level < range.begin
                  STATE_LABELS.dig(@name, :low)
                else
                  STATE_LABELS.dig(@name, :optimal)
                end
              end

              INFLUENCE_MAP = {
                dopamine:       %i[learning_rate exploration_bias],
                serotonin:      %i[patience_factor],
                norepinephrine: %i[arousal_level attention_precision],
                acetylcholine:  %i[memory_encoding attention_precision]
              }.freeze

              def influence_on(target_property)
                relevant = INFLUENCE_MAP.fetch(@name, [])
                return 0.0 unless relevant.include?(target_property)

                scale(@level)
              end

              def to_h
                {
                  name:        @name,
                  level:       @level.round(4),
                  baseline:    @baseline.round(4),
                  state:       state_label,
                  optimal:     optimal?,
                  event_count: @events.size
                }
              end

              private

              def clamp(value)
                value.clamp(LEVEL_FLOOR, LEVEL_CEILING)
              end

              def scale(value)
                (value - DEFAULT_LEVEL) * 2.0
              end

              def record_event(type, amount, reason, old_level)
                @events << {
                  type:      type,
                  amount:    amount,
                  reason:    reason,
                  old_level: old_level.round(4),
                  new_level: @level.round(4),
                  timestamp: Time.now.utc
                }
                @events.shift while @events.size > MAX_EVENTS
              end
            end
          end
        end
      end
    end
  end
end
