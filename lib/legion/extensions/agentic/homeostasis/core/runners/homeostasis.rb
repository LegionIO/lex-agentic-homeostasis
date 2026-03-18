# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Core
          module Runners
            module Homeostasis
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def regulate(tick_results: {}, **)
                observations = extract_observations(tick_results)
                signals = regulator.regulate(observations)
                allostatic_load.update(regulator)

                # Adapt setpoints slowly when system is stable
                regulator.adapt_setpoints if allostatic_load.classification == :healthy

                Legion::Logging.debug "[homeostasis] regulated #{signals.size} subsystems, " \
                                      "health=#{regulator.regulation_health.round(2)}, " \
                                      "allostatic=#{allostatic_load.load.round(2)}"

                {
                  signals:              signals,
                  regulation_health:    regulator.regulation_health,
                  health_label:         regulator.health_label,
                  allostatic_load:      allostatic_load.load,
                  allostatic_class:     allostatic_load.classification,
                  subsystems_regulated: signals.size,
                  worst_deviation:      regulator.worst_deviation
                }
              end

              def modulation_for(subsystem:, **)
                sym = subsystem.to_sym
                signal = regulator.signals[sym]
                sp_status = regulator.subsystem_status(sym)

                Legion::Logging.debug "[homeostasis] modulation query: #{sym} -> #{signal&.dig(:type) || :unknown}"

                {
                  subsystem:       sym,
                  signal:          signal || { type: :hold, magnitude: 0.0, direction: 0.0 },
                  setpoint:        sp_status&.slice(:target, :tolerance, :current_value, :error, :within_tolerance),
                  allostatic_load: allostatic_load.load
                }
              end

              def allostatic_status(**)
                Legion::Logging.debug "[homeostasis] allostatic load=#{allostatic_load.load.round(2)} (#{allostatic_load.classification})"

                allostatic_load.to_h
              end

              def regulation_overview(**)
                {
                  health:           regulator.regulation_health,
                  health_label:     regulator.health_label,
                  allostatic_load:  allostatic_load.to_h,
                  setpoints:        regulator.setpoints.transform_values(&:to_h),
                  signals:          regulator.signals,
                  regulation_count: regulator.regulation_count
                }
              end

              def homeostasis_stats(**)
                {
                  regulation_count:     regulator.regulation_count,
                  regulation_health:    regulator.regulation_health,
                  health_label:         regulator.health_label,
                  allostatic_load:      allostatic_load.load,
                  allostatic_class:     allostatic_load.classification,
                  allostatic_peak:      allostatic_load.peak_load,
                  allostatic_trend:     allostatic_load.trend,
                  subsystems_tracked:   regulator.setpoints.size,
                  subsystems_deviating: regulator.setpoints.values.reject(&:within_tolerance?).size,
                  worst_deviation:      regulator.worst_deviation
                }
              end

              private

              def regulator
                @regulator ||= Helpers::Regulator.new
              end

              def allostatic_load
                @allostatic_load ||= Helpers::AllostaticLoad.new
              end

              def extract_observations(tick_results)
                obs = {}

                obs[:emotional_arousal] = extract_arousal(tick_results)
                obs[:curiosity_intensity] = extract_curiosity(tick_results)
                obs[:cognitive_load] = extract_load(tick_results)
                obs[:memory_health] = extract_memory_health(tick_results)
                obs[:prediction_accuracy] = extract_prediction(tick_results)
                obs[:trust_stability] = extract_trust(tick_results)
                obs[:attention_breadth] = extract_attention(tick_results)

                obs.compact
              end

              def extract_arousal(tick_results)
                emotion = tick_results[:emotional_evaluation]
                return nil unless emotion.is_a?(Hash)

                emotion[:arousal] || emotion.dig(:momentum, :arousal) || emotion[:magnitude]
              end

              def extract_curiosity(tick_results)
                curiosity = tick_results[:working_memory_integration]
                return nil unless curiosity.is_a?(Hash)

                curiosity[:curiosity_intensity] || curiosity[:intensity]
              end

              def extract_load(tick_results)
                elapsed = tick_results[:elapsed]
                budget = tick_results[:budget]
                return nil unless elapsed.is_a?(Numeric) && budget.is_a?(Numeric) && budget.positive?

                (elapsed / budget).clamp(0.0, 1.0)
              end

              def extract_memory_health(tick_results)
                memory = tick_results[:memory_consolidation]
                return nil unless memory.is_a?(Hash) && memory[:total].is_a?(Numeric) && memory[:total].positive?

                retained = (memory[:total] - (memory[:pruned] || 0)).to_f / memory[:total]
                retained.clamp(0.0, 1.0)
              end

              def extract_prediction(tick_results)
                prediction = tick_results[:prediction_engine]
                return nil unless prediction.is_a?(Hash)

                prediction[:accuracy] || prediction[:confidence]
              end

              def extract_trust(tick_results)
                reflection = tick_results[:post_tick_reflection]
                return nil unless reflection.is_a?(Hash)

                reflection[:cognitive_health]
              end

              def extract_attention(tick_results)
                attention = tick_results[:sensory_processing]
                return nil unless attention.is_a?(Hash)

                return unless attention[:total_signals].is_a?(Numeric) && attention[:total_signals].positive?

                (attention[:passed] || attention[:accepted] || 0).to_f / attention[:total_signals]
              end
            end
          end
        end
      end
    end
  end
end
