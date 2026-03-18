# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Pendulum
          module Helpers
            class Pendulum
              attr_reader :id, :pole_pair, :amplitude, :period, :damping, :current_position, :created_at, :swings

              def initialize(pole_pair:, amplitude: 0.5, period: 10.0, damping: Constants::DAMPING_RATE)
                raise ArgumentError, "unknown pole_pair: #{pole_pair}" unless Constants.valid_pole_pair?(pole_pair)
                raise ArgumentError, 'amplitude must be 0.0..1.0' unless amplitude.between?(0.0, 1.0)
                raise ArgumentError, 'period must be positive' unless period.positive?
                raise ArgumentError, 'damping must be >= 0' unless damping >= 0.0

                @id               = SecureRandom.uuid
                @pole_pair        = pole_pair
                @amplitude        = amplitude.clamp(0.0, 1.0)
                @period           = period.to_f
                @damping          = damping.to_f
                @current_position = 0.0
                @created_at       = Time.now.utc
                @swings           = 0
              end

              def swing!(force: 0.0)
                force_clamped = force.to_f.clamp(-1.0, 1.0)
                @current_position = (@current_position + force_clamped).clamp(-1.0, 1.0)
                @swings += 1
                @current_position
              end

              def damp!
                @amplitude = (@amplitude * (1.0 - @damping)).round(10).clamp(0.0, 1.0)
                @current_position = (@current_position * (1.0 - @damping)).round(10).clamp(-1.0, 1.0)
                @amplitude
              end

              def position_at(time)
                elapsed = time.to_f
                angular_frequency = (2.0 * Math::PI) / @period
                decay = Math.exp(-@damping * elapsed)
                (@amplitude * decay * Math.cos(angular_frequency * elapsed)).round(10).clamp(-1.0, 1.0)
              end

              def at_pole_a?
                @current_position <= -0.5
              end

              def at_pole_b?
                @current_position >= 0.5
              end

              def amplitude_label
                Constants.amplitude_label(@amplitude)
              end

              def resonant_with?(frequency)
                return false unless frequency.positive?

                natural_frequency = 1.0 / @period
                ratio = frequency / natural_frequency
                (ratio - 1.0).abs <= 0.05
              end

              def dominant_pole
                poles = Constants::POLE_PAIRS.fetch(@pole_pair)
                return :neutral if @current_position.abs < 0.1

                @current_position.negative? ? poles[0] : poles[1]
              end

              def to_h
                poles = Constants::POLE_PAIRS.fetch(@pole_pair)
                {
                  id:               @id,
                  pole_pair:        @pole_pair,
                  pole_a:           poles[0],
                  pole_b:           poles[1],
                  amplitude:        @amplitude.round(10),
                  amplitude_label:  amplitude_label,
                  period:           @period,
                  damping:          @damping,
                  current_position: @current_position.round(10),
                  dominant_pole:    dominant_pole,
                  at_pole_a:        at_pole_a?,
                  at_pole_b:        at_pole_b?,
                  swings:           @swings,
                  created_at:       @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
