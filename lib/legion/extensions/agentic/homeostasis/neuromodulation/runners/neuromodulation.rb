# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Neuromodulation
          module Runners
            module Neuromodulation
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def boost_modulator(name:, amount:, reason: nil, **)
                mod_name = name.to_sym
                return { success: false, error: "Unknown modulator: #{name}" } unless Helpers::Constants::MODULATORS.include?(mod_name)

                new_level = neuromod_system.boost(mod_name, amount.to_f, reason: reason)
                Legion::Logging.debug "[neuromodulation] boost #{mod_name} by #{amount} -> #{new_level.round(4)}"
                {
                  success:   true,
                  modulator: mod_name,
                  level:     new_level.round(4),
                  state:     neuromod_system.modulators[mod_name].state_label
                }
              end

              def suppress_modulator(name:, amount:, reason: nil, **)
                mod_name = name.to_sym
                return { success: false, error: "Unknown modulator: #{name}" } unless Helpers::Constants::MODULATORS.include?(mod_name)

                new_level = neuromod_system.suppress(mod_name, amount.to_f, reason: reason)
                Legion::Logging.debug "[neuromodulation] suppress #{mod_name} by #{amount} -> #{new_level.round(4)}"
                {
                  success:   true,
                  modulator: mod_name,
                  level:     new_level.round(4),
                  state:     neuromod_system.modulators[mod_name].state_label
                }
              end

              def modulator_level(name:, **)
                mod_name = name.to_sym
                return { success: false, error: "Unknown modulator: #{name}" } unless Helpers::Constants::MODULATORS.include?(mod_name)

                level = neuromod_system.level(mod_name)
                {
                  success:   true,
                  modulator: mod_name,
                  level:     level.round(4),
                  state:     neuromod_system.modulators[mod_name].state_label
                }
              end

              def all_modulator_levels(**)
                levels = neuromod_system.all_levels
                Legion::Logging.debug "[neuromodulation] all levels: #{levels.map { |k, v| "#{k}=#{v.round(3)}" }.join(' ')}"
                { success: true, levels: levels.transform_values { |v| v.round(4) } }
              end

              def cognitive_influence(**)
                influences = neuromod_system.composite_influences
                Legion::Logging.debug '[neuromodulation] cognitive influence snapshot'
                { success: true, influences: influences }
              end

              def is_optimal(name:, **) # rubocop:disable Naming/PredicatePrefix
                mod_name = name.to_sym
                return { success: false, error: "Unknown modulator: #{name}" } unless Helpers::Constants::MODULATORS.include?(mod_name)

                optimal = neuromod_system.modulators[mod_name].optimal?
                {
                  success:   true,
                  modulator: mod_name,
                  optimal:   optimal,
                  level:     neuromod_system.level(mod_name).round(4),
                  range:     Helpers::Constants::OPTIMAL_RANGES[mod_name].to_s
                }
              end

              def system_balance(**)
                score = neuromod_system.balance_score
                states = neuromod_system.modulators.transform_values(&:state_label)
                status = if score >= 1.0
                           :fully_balanced
                         elsif score >= 0.75
                           :mostly_balanced
                         elsif score >= 0.5
                           :partially_balanced
                         else
                           :imbalanced
                         end
                Legion::Logging.debug "[neuromodulation] system balance: #{score.round(2)} status=#{status}"
                {
                  success: true,
                  score:   score.round(4),
                  status:  status,
                  states:  states
                }
              end

              def modulator_history(name:, limit: 20, **)
                mod_name = name.to_sym
                return { success: false, error: "Unknown modulator: #{name}" } unless Helpers::Constants::MODULATORS.include?(mod_name)

                events = neuromod_system.modulators[mod_name].events.last(limit.to_i)
                {
                  success:   true,
                  modulator: mod_name,
                  events:    events,
                  count:     events.size
                }
              end

              def update_neuromodulation(**)
                neuromod_system.tick
                levels = neuromod_system.all_levels
                Legion::Logging.debug '[neuromodulation] drift tick completed'
                {
                  success: true,
                  action:  :drift_tick,
                  levels:  levels.transform_values { |v| v.round(4) }
                }
              end

              def neuromodulation_stats(**)
                {
                  success: true,
                  system:  neuromod_system.to_h
                }
              end

              private

              def neuromod_system
                @neuromod_system ||= Helpers::ModulatorSystem.new
              end
            end
          end
        end
      end
    end
  end
end
