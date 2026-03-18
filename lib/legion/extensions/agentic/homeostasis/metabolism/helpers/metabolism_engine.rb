# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Metabolism
          module Helpers
            class MetabolismEngine
              include Constants

              MAX_EFFICIENCY_HISTORY = 200

              def initialize
                @reserves = {}
                @efficiency_history = []
              end

              def create_reserve(max_energy: MAX_ENERGY, metabolic_rate: RESTING_METABOLIC_RATE, efficiency: 1.0)
                reserve = EnergyReserve.new(max_energy: max_energy, metabolic_rate: metabolic_rate, efficiency: efficiency)
                @reserves[reserve.id] = reserve
                reserve
              end

              def spend_energy(reserve_id:, operation_type:)
                reserve = fetch_reserve(reserve_id)
                cost = OPERATION_COSTS.fetch(operation_type) do
                  raise ArgumentError, "Unknown operation type: #{operation_type.inspect}"
                end
                actual_spent = reserve.spend!(cost)
                record_efficiency(reserve)
                {
                  reserve_id:     reserve_id,
                  operation_type: operation_type,
                  base_cost:      cost,
                  actual_spent:   actual_spent.round(10),
                  current_energy: reserve.current_energy.round(10),
                  state:          reserve.state
                }
              end

              def recover(reserve_id:, duration: 1.0)
                reserve = fetch_reserve(reserve_id)
                amount = (RECOVERY_RATE * duration.clamp(0.0, Float::INFINITY)).round(10)
                gained = reserve.recover!(amount)
                record_efficiency(reserve)
                {
                  reserve_id:     reserve_id,
                  duration:       duration,
                  energy_gained:  gained.round(10),
                  current_energy: reserve.current_energy.round(10),
                  state:          reserve.state
                }
              end

              def catabolize(reserve_id:, complexity: 1.0)
                reserve = fetch_reserve(reserve_id)
                result = reserve.catabolize!(complexity: complexity)
                result.merge(reserve_id: reserve_id)
              end

              def anabolize(reserve_id:, energy_cost: 5.0)
                reserve = fetch_reserve(reserve_id)
                result = reserve.anabolize!(energy_cost: energy_cost)
                result.merge(reserve_id: reserve_id)
              end

              def run_cycle(reserve_id:, operations: [])
                reserve = fetch_reserve(reserve_id)
                cycle   = MetabolicCycle.new

                operations.each do |op_type|
                  cost_base = OPERATION_COSTS.fetch(op_type, 0.0)
                  reserve.spend!(cost_base) if cost_base > 0.0
                  cycle.record_operation(operation_type: op_type, energy_spent: cost_base)
                end

                reserve.spend!(reserve.metabolic_rate)
                cycle.record_operation(operation_type: :resting_rate, energy_spent: reserve.metabolic_rate)

                cycle.complete!.merge(reserve_state: reserve.state, reserve_energy: reserve.current_energy.round(10))
              end

              def metabolic_report(reserve_id:)
                reserve = fetch_reserve(reserve_id)
                {
                  reserve:            reserve.to_h,
                  efficiency_history: efficiency_history_for(reserve_id)
                }
              end

              def efficiency_history
                @efficiency_history.dup
              end

              def all_reserves
                @reserves.transform_values(&:to_h)
              end

              private

              def fetch_reserve(id)
                @reserves.fetch(id) { raise ArgumentError, "Unknown reserve: #{id.inspect}" }
              end

              def record_efficiency(reserve)
                @efficiency_history << {
                  reserve_id:  reserve.id,
                  efficiency:  reserve.efficiency.round(10),
                  state:       reserve.state,
                  recorded_at: Time.now.utc
                }
                @efficiency_history.shift while @efficiency_history.size > MAX_EFFICIENCY_HISTORY
              end

              def efficiency_history_for(reserve_id)
                @efficiency_history.select { |e| e[:reserve_id] == reserve_id }
              end
            end
          end
        end
      end
    end
  end
end
