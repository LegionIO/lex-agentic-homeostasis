# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Core
          module Helpers
            class Regulator
              attr_reader :setpoints, :signals, :regulation_count

              def initialize
                @setpoints = build_setpoints
                @signals = {}
                @regulation_count = 0
              end

              def regulate(observations)
                @regulation_count += 1
                new_signals = {}

                observations.each do |subsystem, value|
                  sp = @setpoints[subsystem]
                  next unless sp

                  error = sp.update(value)
                  gain = Constants::REGULATION_GAIN.fetch(subsystem, 0.2)
                  signal = compute_signal(error, sp.tolerance, gain)

                  new_signals[subsystem] = {
                    type:             classify_signal(signal),
                    magnitude:        signal.abs,
                    direction:        signal,
                    error:            error,
                    within_tolerance: sp.within_tolerance?
                  }
                end

                @signals = new_signals
                new_signals
              end

              def regulation_health
                return 1.0 if @setpoints.empty?

                in_tolerance = @setpoints.values.count(&:within_tolerance?)
                in_tolerance.to_f / @setpoints.size
              end

              def health_label
                health = regulation_health
                Constants::REGULATION_HEALTH.each do |range, label|
                  return label if range.cover?(health)
                end
                :unknown
              end

              def worst_deviation
                worst = @setpoints.values.max_by(&:deviation_ratio)
                return nil unless worst

                { subsystem: worst.name, deviation_ratio: worst.deviation_ratio, error: worst.error }
              end

              def subsystem_status(subsystem)
                sp = @setpoints[subsystem]
                return nil unless sp

                signal = @signals[subsystem]
                sp.to_h.merge(signal: signal)
              end

              def adapt_setpoints
                @setpoints.each_value do |sp|
                  sp.adapt_target if sp.within_tolerance?
                end
              end

              def to_h
                {
                  setpoints:        @setpoints.transform_values(&:to_h),
                  signals:          @signals,
                  regulation_count: @regulation_count,
                  health:           regulation_health,
                  health_label:     health_label
                }
              end

              private

              def build_setpoints
                Constants::SETPOINTS.to_h do |name, config|
                  [name, Setpoint.new(name: name, target: config[:target], tolerance: config[:tolerance])]
                end
              end

              def compute_signal(error, tolerance, gain)
                return 0.0 if error.abs <= tolerance * 0.1

                correction = -error * gain
                correction.clamp(Constants::MAX_DAMPEN, Constants::MAX_AMPLIFY)
              end

              def classify_signal(signal)
                if signal < -0.01
                  :dampen
                elsif signal > 0.01
                  :amplify
                else
                  :hold
                end
              end
            end
          end
        end
      end
    end
  end
end
