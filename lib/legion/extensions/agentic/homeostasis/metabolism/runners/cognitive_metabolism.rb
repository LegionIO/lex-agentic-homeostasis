# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Metabolism
          module Runners
            module CognitiveMetabolism
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def create_reserve(max_energy: Helpers::Constants::MAX_ENERGY,
                                 metabolic_rate: Helpers::Constants::RESTING_METABOLIC_RATE,
                                 efficiency: 1.0, **)
                reserve = engine.create_reserve(max_energy: max_energy, metabolic_rate: metabolic_rate, efficiency: efficiency)
                log.debug("[cognitive_metabolism] reserve created: id=#{reserve.id} max_energy=#{reserve.max_energy}")
                { success: true, reserve: reserve.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def spend_energy(reserve_id:, operation_type:, **)
                result = engine.spend_energy(reserve_id: reserve_id, operation_type: operation_type)
                log.debug("[cognitive_metabolism] spend: reserve=#{reserve_id} op=#{operation_type} " \
                          "spent=#{result[:actual_spent]} state=#{result[:state]}")
                { success: true }.merge(result)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def recover(reserve_id:, duration: 1.0, **)
                result = engine.recover(reserve_id: reserve_id, duration: duration)
                log.debug("[cognitive_metabolism] recover: reserve=#{reserve_id} " \
                          "gained=#{result[:energy_gained]} state=#{result[:state]}")
                { success: true }.merge(result)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def catabolize(reserve_id:, complexity: 1.0, **)
                result = engine.catabolize(reserve_id: reserve_id, complexity: complexity)
                log.debug("[cognitive_metabolism] catabolize: reserve=#{reserve_id} " \
                          "complexity=#{complexity} gained=#{result[:energy_gained]}")
                { success: true }.merge(result)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def anabolize(reserve_id:, energy_cost: 5.0, **)
                result = engine.anabolize(reserve_id: reserve_id, energy_cost: energy_cost)
                log.debug("[cognitive_metabolism] anabolize: reserve=#{reserve_id} " \
                          "cost=#{energy_cost} value=#{result[:structure_value]}")
                { success: true }.merge(result)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def metabolic_status(reserve_id:, **)
                result = engine.metabolic_report(reserve_id: reserve_id)
                log.debug("[cognitive_metabolism] status: reserve=#{reserve_id} state=#{result[:reserve][:state]}")
                { success: true }.merge(result)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def run_cycle(reserve_id:, operations: [], **)
                result = engine.run_cycle(reserve_id: reserve_id, operations: operations)
                log.debug("[cognitive_metabolism] cycle: reserve=#{reserve_id} " \
                          "ops=#{result[:cycle_count]} spent=#{result[:energy_spent_this_cycle]} state=#{result[:reserve_state]}")
                { success: true }.merge(result)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def run_all_cycles(**)
                reserves = engine.all_reserves
                if reserves.empty?
                  log.info('[cognitive_metabolism] run_all_cycles: no reserves to cycle')
                  return { success: true, cycled: 0, reserves: 0, results: [], failures: [] }
                end

                results  = []
                failures = []

                reserves.each_key do |id|
                  result = engine.run_cycle(reserve_id: id, operations: [])
                  log.debug("[cognitive_metabolism] auto-cycle: reserve=#{id} state=#{result[:reserve_state]}")
                  results << result
                rescue StandardError => e
                  log.error("[cognitive_metabolism] auto-cycle failed for reserve=#{id}: #{e.message}")
                  failures << { reserve_id: id, error: e.message }
                end

                log.info("[cognitive_metabolism] run_all_cycles: #{results.size}/#{reserves.size} reserves cycled")
                { success: failures.empty?, cycled: results.size, reserves: reserves.size, results: results, failures: failures }
              rescue StandardError => e
                log.error("[cognitive_metabolism] run_all_cycles failed: #{e.message}")
                { success: false, cycled: 0, reserves: 0, results: [], failures: [], error: e.message }
              end

              private

              def engine
                @engine ||= Helpers::MetabolismEngine.new
              end
            end
          end
        end
      end
    end
  end
end
