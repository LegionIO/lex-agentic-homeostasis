# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Homeostasis
          module Helpers
            class CognitiveVariable
              include Constants

              attr_reader :id, :name, :category, :setpoint, :tolerance, :current_value,
                          :correction_count, :created_at
              attr_accessor :correction_rate

              def initialize(name:, category: :general, setpoint: DEFAULT_SETPOINT,
                             tolerance: DEFAULT_TOLERANCE, correction_rate: CORRECTION_RATE,
                             initial_value: nil)
                @id               = SecureRandom.uuid
                @name             = name
                @category         = category.to_sym
                @setpoint         = setpoint.to_f.clamp(0.0, 1.0)
                @tolerance        = tolerance.to_f.clamp(0.0, 0.5)
                @correction_rate  = correction_rate.to_f.clamp(0.01, MAX_CORRECTION)
                @current_value    = (initial_value || @setpoint).to_f.clamp(0.0, 1.0)
                @correction_count = 0
                @created_at       = Time.now.utc
              end

              def deviation
                (@current_value - @setpoint).abs.round(10)
              end

              def deviation_label
                match = DEVIATION_LABELS.find { |range, _| range.cover?(deviation) }
                match ? match.last : :extreme
              end

              def in_range?
                deviation <= @tolerance
              end

              def balance_score
                [1.0 - (deviation / [0.5, @tolerance * 3].max), 0.0].max.round(10)
              end

              def balance_label
                match = BALANCE_LABELS.find { |range, _| range.cover?(balance_score) }
                match ? match.last : :critical
              end

              def perturb!(amount:)
                @current_value = (@current_value + amount).clamp(0.0, 1.0).round(10)
                self
              end

              def correct!
                return self if in_range?

                direction = @current_value > @setpoint ? -1 : 1
                step = [deviation, @correction_rate].min
                @current_value = (@current_value + (direction * step)).clamp(0.0, 1.0).round(10)
                @correction_count += 1
                self
              end

              def drift!(rate: DRIFT_RATE)
                direction = rand > 0.5 ? 1 : -1
                @current_value = (@current_value + (direction * rate)).clamp(0.0, 1.0).round(10)
                self
              end

              def reset!
                @current_value = @setpoint
                self
              end

              def to_h
                {
                  id:               @id,
                  name:             @name,
                  category:         @category,
                  setpoint:         @setpoint,
                  tolerance:        @tolerance,
                  current_value:    @current_value,
                  deviation:        deviation,
                  deviation_label:  deviation_label,
                  in_range:         in_range?,
                  balance_score:    balance_score,
                  balance_label:    balance_label,
                  correction_count: @correction_count,
                  correction_rate:  @correction_rate,
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
