# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Pendulum
          module Helpers
            class PendulumEngine
              attr_reader :pendulums

              def initialize
                @pendulums = {}
              end

              def create_pendulum(pole_pair:, amplitude: 0.5, period: 10.0, damping: Constants::DAMPING_RATE)
                raise ArgumentError, "max pendulums (#{Constants::MAX_PENDULUMS}) reached" if @pendulums.size >= Constants::MAX_PENDULUMS

                pendulum = Pendulum.new(
                  pole_pair: pole_pair,
                  amplitude: amplitude,
                  period:    period,
                  damping:   damping
                )
                @pendulums[pendulum.id] = pendulum
                pendulum
              end

              def swing(pendulum_id, force: 0.0)
                p = @pendulums[pendulum_id]
                return nil unless p

                p.swing!(force: force)
                p
              end

              def damp_all!
                @pendulums.each_value(&:damp!)
              end

              def check_resonance(frequency)
                return [] unless frequency.positive?

                @pendulums.values.select { |p| p.resonant_with?(frequency) }.map(&:id)
              end

              def dominant_pole(pendulum_id)
                p = @pendulums[pendulum_id]
                return nil unless p

                p.dominant_pole
              end

              def most_active(limit: 5)
                @pendulums.values
                          .sort_by { |p| -p.amplitude }
                          .first(limit)
              end

              def most_damped(limit: 5)
                @pendulums.values
                          .sort_by(&:amplitude)
                          .first(limit)
              end

              def pendulum_report
                {
                  total:       @pendulums.size,
                  max:         Constants::MAX_PENDULUMS,
                  pole_pairs:  @pendulums.values.group_by(&:pole_pair).transform_values(&:count),
                  most_active: most_active(limit: 3).map(&:to_h),
                  most_damped: most_damped(limit: 3).map(&:to_h)
                }
              end

              def get(pendulum_id)
                @pendulums[pendulum_id]
              end

              def count
                @pendulums.size
              end
            end
          end
        end
      end
    end
  end
end
