# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Metabolism
          module Helpers
            class EnergyReserve
              include Constants

              attr_reader :id, :current_energy, :max_energy, :metabolic_rate, :efficiency, :created_at

              def initialize(max_energy: MAX_ENERGY, metabolic_rate: RESTING_METABOLIC_RATE, efficiency: 1.0)
                @id             = SecureRandom.uuid
                @max_energy     = max_energy.clamp(1.0, Float::INFINITY)
                @current_energy = @max_energy
                @metabolic_rate = metabolic_rate.clamp(0.0, Float::INFINITY)
                @efficiency     = efficiency.clamp(0.0, 1.0)
                @created_at     = Time.now.utc
              end

              def energy_ratio
                (@current_energy / @max_energy).clamp(0.0, 1.0)
              end

              def state
                Constants.label_for(energy_ratio)
              end

              def depleted?
                state == :depleted
              end

              def spend!(amount)
                effective_cost = amount / @efficiency.clamp(0.01, 1.0)
                before = @current_energy
                @current_energy = (@current_energy - effective_cost).clamp(0.0, @max_energy)
                @efficiency = (@efficiency - EFFICIENCY_DECAY).clamp(0.0, 1.0)
                before - @current_energy
              end

              def recover!(amount)
                before = @current_energy
                @current_energy = (@current_energy + amount).clamp(0.0, @max_energy)
                @efficiency = (@efficiency + (EFFICIENCY_DECAY * 0.5)).clamp(0.0, 1.0)
                @current_energy - before
              end

              def catabolize!(complexity: 1.0)
                energy_gained = (complexity * 10.0).round(10)
                @current_energy = (@current_energy + energy_gained).clamp(0.0, @max_energy)
                { energy_gained: energy_gained, current_energy: @current_energy.round(10), state: state }
              end

              def anabolize!(energy_cost: 5.0)
                raise ArgumentError, 'insufficient energy for anabolism' if @current_energy < energy_cost

                @current_energy = (@current_energy - energy_cost).clamp(0.0, @max_energy)
                structure_value = (energy_cost * @efficiency).round(10)
                { energy_spent: energy_cost, structure_value: structure_value, current_energy: @current_energy.round(10), state: state }
              end

              def to_h
                {
                  id:             @id,
                  current_energy: @current_energy.round(10),
                  max_energy:     @max_energy,
                  metabolic_rate: @metabolic_rate,
                  efficiency:     @efficiency.round(10),
                  energy_ratio:   energy_ratio.round(10),
                  state:          state,
                  depleted:       depleted?,
                  created_at:     @created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
