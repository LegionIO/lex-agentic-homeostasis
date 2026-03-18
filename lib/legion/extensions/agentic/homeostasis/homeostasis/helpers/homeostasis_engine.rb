# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Homeostasis
          module Helpers
            class HomeostasisEngine
              include Constants

              def initialize
                @variables = {}
              end

              def create_variable(name:, category: :general, setpoint: DEFAULT_SETPOINT,
                                  tolerance: DEFAULT_TOLERANCE, correction_rate: CORRECTION_RATE,
                                  initial_value: nil)
                prune_if_needed
                variable = CognitiveVariable.new(
                  name:            name,
                  category:        category,
                  setpoint:        setpoint,
                  tolerance:       tolerance,
                  correction_rate: correction_rate,
                  initial_value:   initial_value
                )
                @variables[variable.id] = variable
                variable
              end

              def perturb(variable_id:, amount:)
                variable = @variables[variable_id]
                return nil unless variable

                variable.perturb!(amount: amount)
              end

              def correct(variable_id:)
                variable = @variables[variable_id]
                return nil unless variable

                variable.correct!
              end

              def correct_all
                out_of_range = @variables.values.reject(&:in_range?)
                out_of_range.each(&:correct!)
                out_of_range.size
              end

              def drift_all(rate: DRIFT_RATE)
                @variables.each_value { |v| v.drift!(rate: rate) }
                @variables.size
              end

              def reset_variable(variable_id:)
                variable = @variables[variable_id]
                return nil unless variable

                variable.reset!
              end

              def out_of_range_variables
                @variables.values.reject(&:in_range?)
              end

              def variables_by_category(category:)
                cat = category.to_sym
                @variables.values.select { |v| v.category == cat }
              end

              def most_deviated(limit: 5)
                @variables.values.sort_by { |v| -v.deviation }.first(limit)
              end

              def overall_balance
                return 1.0 if @variables.empty?

                scores = @variables.values.map(&:balance_score)
                (scores.sum / scores.size).round(10)
              end

              def overall_balance_label
                match = BALANCE_LABELS.find { |range, _| range.cover?(overall_balance) }
                match ? match.last : :critical
              end

              def stress_index
                return 0.0 if @variables.empty?

                deviations = @variables.values.map(&:deviation)
                (deviations.sum / deviations.size).round(10)
              end

              def homeostasis_report
                {
                  total_variables:       @variables.size,
                  in_range_count:        @variables.values.count(&:in_range?),
                  out_of_range_count:    out_of_range_variables.size,
                  overall_balance:       overall_balance,
                  overall_balance_label: overall_balance_label,
                  stress_index:          stress_index,
                  most_deviated:         most_deviated(limit: 3).map(&:to_h),
                  category_breakdown:    category_breakdown
                }
              end

              def to_h
                {
                  total_variables:       @variables.size,
                  overall_balance:       overall_balance,
                  overall_balance_label: overall_balance_label,
                  stress_index:          stress_index
                }
              end

              private

              def category_breakdown
                breakdown = {}
                @variables.values.group_by(&:category).each do |cat, vars|
                  scores = vars.map(&:balance_score)
                  breakdown[cat] = {
                    count:        vars.size,
                    avg_balance:  (scores.sum / scores.size).round(10),
                    out_of_range: vars.count { |v| !v.in_range? }
                  }
                end
                breakdown
              end

              def prune_if_needed
                return if @variables.size < MAX_VARIABLES

                best = @variables.values.max_by(&:balance_score)
                @variables.delete(best.id) if best
              end
            end
          end
        end
      end
    end
  end
end
