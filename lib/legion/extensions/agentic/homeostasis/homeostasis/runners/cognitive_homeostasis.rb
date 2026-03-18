# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Homeostasis
          module Runners
            module CognitiveHomeostasis
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_cognitive_variable(name:, category: :general, setpoint: nil,
                                            tolerance: nil, correction_rate: nil,
                                            initial_value: nil, **)
                var = engine.create_variable(
                  name:            name,
                  category:        category,
                  setpoint:        setpoint || Helpers::Constants::DEFAULT_SETPOINT,
                  tolerance:       tolerance || Helpers::Constants::DEFAULT_TOLERANCE,
                  correction_rate: correction_rate || Helpers::Constants::CORRECTION_RATE,
                  initial_value:   initial_value
                )
                { success: true }.merge(var.to_h)
              end

              def perturb_variable(variable_id:, amount:, **)
                result = engine.perturb(variable_id: variable_id, amount: amount)
                return { success: false, error: 'variable not found' } unless result

                { success: true }.merge(result.to_h)
              end

              def correct_variable(variable_id:, **)
                result = engine.correct(variable_id: variable_id)
                return { success: false, error: 'variable not found' } unless result

                { success: true }.merge(result.to_h)
              end

              def correct_all_variables(**)
                corrected = engine.correct_all
                { success: true, corrected: corrected }
              end

              def drift_all_variables(rate: nil, **)
                r = rate || Helpers::Constants::DRIFT_RATE
                count = engine.drift_all(rate: r)
                { success: true, drifted: count }
              end

              def reset_variable(variable_id:, **)
                result = engine.reset_variable(variable_id: variable_id)
                return { success: false, error: 'variable not found' } unless result

                { success: true }.merge(result.to_h)
              end

              def out_of_range_report(**)
                vars = engine.out_of_range_variables
                { success: true, count: vars.size, variables: vars.map(&:to_h) }
              end

              def variables_by_category_report(category:, **)
                vars = engine.variables_by_category(category: category)
                { success: true, category: category.to_sym, count: vars.size, variables: vars.map(&:to_h) }
              end

              def most_deviated_report(limit: 5, **)
                vars = engine.most_deviated(limit: limit)
                { success: true, limit: limit, variables: vars.map(&:to_h) }
              end

              def homeostasis_report(**)
                engine.homeostasis_report
              end

              def update_cognitive_homeostasis(**)
                corrected = engine.correct_all
                { success: true, corrected: corrected, stats: engine.to_h }
              end

              def cognitive_homeostasis_stats(**)
                engine.to_h
              end
            end
          end
        end
      end
    end
  end
end
