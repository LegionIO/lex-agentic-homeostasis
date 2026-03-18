# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Neuromodulation
          module Helpers
            class ModulatorSystem
              include Constants

              attr_reader :modulators

              def initialize
                @modulators = MODULATORS.to_h { |name| [name, Modulator.new(name)] }
              end

              def boost(name, amount, reason: nil)
                validate_name!(name)
                result = @modulators[name].boost(amount, reason: reason)
                apply_interactions(name)
                result
              end

              def suppress(name, amount, reason: nil)
                validate_name!(name)
                result = @modulators[name].suppress(amount, reason: reason)
                apply_interactions(name)
                result
              end

              def level(name)
                validate_name!(name)
                @modulators[name].level
              end

              def all_levels
                @modulators.transform_values(&:level)
              end

              def tick
                @modulators.each_value(&:drift_to_baseline)
              end

              def learning_rate_modifier
                da = @modulators[:dopamine].level
                ach = @modulators[:acetylcholine].level
                clamp((da * 0.6) + (ach * 0.4))
              end

              def attention_precision
                ne = @modulators[:norepinephrine].level
                ach = @modulators[:acetylcholine].level
                clamp((ne * 0.5) + (ach * 0.5))
              end

              def exploration_bias
                @modulators[:dopamine].level
              end

              def patience_factor
                @modulators[:serotonin].level
              end

              def memory_encoding_strength
                @modulators[:acetylcholine].level
              end

              def arousal_level
                @modulators[:norepinephrine].level
              end

              def composite_influences
                {
                  learning_rate_modifier:   learning_rate_modifier.round(4),
                  attention_precision:      attention_precision.round(4),
                  exploration_bias:         exploration_bias.round(4),
                  patience_factor:          patience_factor.round(4),
                  memory_encoding_strength: memory_encoding_strength.round(4),
                  arousal_level:            arousal_level.round(4)
                }
              end

              def balance_score
                in_range = @modulators.values.count(&:optimal?)
                in_range.to_f / @modulators.size
              end

              def to_h
                {
                  modulators: @modulators.transform_values(&:to_h),
                  influences: composite_influences,
                  balance:    balance_score.round(4)
                }
              end

              private

              def validate_name!(name)
                raise ArgumentError, "Unknown modulator: #{name}" unless MODULATORS.include?(name)
              end

              def clamp(value)
                value.clamp(LEVEL_FLOOR, LEVEL_CEILING)
              end

              def apply_interactions(changed)
                case changed
                when :dopamine
                  high_da = @modulators[:dopamine].level > 0.7
                  @modulators[:serotonin].suppress(0.05, reason: :dopamine_suppression) if high_da
                when :norepinephrine
                  high_ne = @modulators[:norepinephrine].level > 0.8
                  @modulators[:acetylcholine].suppress(0.03, reason: :ne_suppression) if high_ne
                end
              end
            end
          end
        end
      end
    end
  end
end
