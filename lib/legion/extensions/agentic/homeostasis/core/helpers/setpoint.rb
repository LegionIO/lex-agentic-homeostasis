# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Core
          module Helpers
            class Setpoint
              attr_reader :name, :target, :tolerance, :current_value, :error, :history

              def initialize(name:, target:, tolerance:)
                @name = name
                @target = target.to_f
                @tolerance = tolerance.to_f
                @current_value = @target
                @error = 0.0
                @history = []
              end

              def update(observed_value)
                @current_value = observed_value.to_f
                @error = @current_value - @target
                @history << { value: @current_value, error: @error, at: Time.now.utc }
                @history = @history.last(Constants::MAX_REGULATION_HISTORY)
                @error
              end

              def within_tolerance?
                @error.abs <= @tolerance
              end

              def deviation_ratio
                return 0.0 if @tolerance.zero?

                (@error.abs / @tolerance).clamp(0.0, 3.0)
              end

              def adapt_target(alpha: Constants::SETPOINT_ADAPTATION_ALPHA)
                @target += (alpha * @error)
                @target = @target.clamp(0.0, 1.0)
              end

              def trend(window: 10)
                recent = @history.last(window)
                return :insufficient_data if recent.size < 3

                values = recent.map { |h| h[:value] }
                slope = linear_slope(values)

                if slope > 0.01
                  :rising
                elsif slope < -0.01
                  :falling
                else
                  :stable
                end
              end

              def to_h
                {
                  name:             @name,
                  target:           @target,
                  tolerance:        @tolerance,
                  current_value:    @current_value,
                  error:            @error,
                  within_tolerance: within_tolerance?,
                  deviation_ratio:  deviation_ratio,
                  trend:            trend,
                  history_size:     @history.size
                }
              end

              private

              def linear_slope(values)
                n = values.size
                return 0.0 if n < 2

                sum_x = n * (n - 1) / 2.0
                sum_y = values.sum
                sum_xy = values.each_with_index.sum { |y, x| x * y }
                sum_x2 = (0...n).sum { |x| x * x }

                denominator = (n * sum_x2) - (sum_x * sum_x)
                return 0.0 if denominator.zero?

                ((n * sum_xy) - (sum_x * sum_y)) / denominator
              end
            end
          end
        end
      end
    end
  end
end
