# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FossilFuel
          module Helpers
            class Combustion
              attr_reader :id, :reserve_id, :fuel_amount, :grade,
                          :energy_released, :burned_at

              def initialize(reserve_id:, fuel_amount:, grade: :crude, quality: 0.5)
                validate_grade!(grade)
                @id              = SecureRandom.uuid
                @reserve_id      = reserve_id
                @fuel_amount     = fuel_amount.to_f.clamp(0.0, 1.0).round(10)
                @grade           = grade.to_sym
                @energy_released = calculate_energy(fuel_amount, quality)
                @burned_at       = Time.now.utc
              end

              def efficient?
                @energy_released > (@fuel_amount * 0.7)
              end

              def wasteful?
                @energy_released < (@fuel_amount * 0.3)
              end

              def energy_label
                Constants.label_for(Constants::ENERGY_LABELS, @energy_released)
              end

              def to_h
                {
                  id:              @id,
                  reserve_id:      @reserve_id,
                  fuel_amount:     @fuel_amount,
                  grade:           @grade,
                  energy_released: @energy_released,
                  energy_label:    energy_label,
                  efficient:       efficient?,
                  wasteful:        wasteful?,
                  burned_at:       @burned_at
                }
              end

              private

              def calculate_energy(amount, quality)
                base = amount * Constants::COMBUSTION_EFFICIENCY
                grade_bonus = grade_multiplier
                (base * grade_bonus * (0.5 + (quality * 0.5))).clamp(0.0, 1.0).round(10)
              end

              def grade_multiplier
                { crude: 0.6, refined: 0.8, premium: 1.0, synthetic: 1.2 }
                  .fetch(@grade, 0.6)
              end

              def validate_grade!(val)
                return if Constants::GRADES.include?(val.to_sym)

                raise ArgumentError,
                      "unknown grade: #{val.inspect}; " \
                      "must be one of #{Constants::GRADES.inspect}"
              end
            end
          end
        end
      end
    end
  end
end
