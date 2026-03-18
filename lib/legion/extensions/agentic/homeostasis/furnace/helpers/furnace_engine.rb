# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Furnace
          module Helpers
            class FurnaceEngine
              attr_reader :ores, :crucibles, :alloy_history

              def initialize
                @ores         = {}
                @crucibles    = {}
                @alloy_history = []
              end

              def add_ore(ore_type:, domain:, content:, purity: 0.5, impurity: nil, ore_id: nil)
                return { added: false, reason: :ore_store_full, max: Constants::MAX_ORES } if @ores.size >= Constants::MAX_ORES

                ore = Ore.new(
                  ore_type: ore_type,
                  domain:   domain,
                  content:  content,
                  purity:   purity,
                  impurity: impurity,
                  ore_id:   ore_id
                )
                @ores[ore.ore_id] = ore
                { added: true, ore_id: ore.ore_id, ore: ore.to_h }
              end

              def create_crucible(capacity: 10, crucible_id: nil, temperature: 0.0)
                return { created: false, reason: :crucible_store_full, max: Constants::MAX_CRUCIBLES } if @crucibles.size >= Constants::MAX_CRUCIBLES

                crucible = Crucible.new(capacity: capacity, crucible_id: crucible_id, temperature: temperature)
                @crucibles[crucible.crucible_id] = crucible
                { created: true, crucible_id: crucible.crucible_id, crucible: crucible.to_h }
              end

              def load_ore(ore_id:, crucible_id:)
                ore      = @ores[ore_id]
                crucible = @crucibles[crucible_id]

                return { loaded: false, reason: :ore_not_found }      unless ore
                return { loaded: false, reason: :crucible_not_found } unless crucible

                result = crucible.load_ore(ore_id)
                result.merge(ore_id: ore_id, crucible_id: crucible_id)
              end

              def heat_crucible(crucible_id:, rate: Constants::HEAT_RATE)
                crucible = @crucibles[crucible_id]
                return { heated: false, reason: :not_found } unless crucible

                before = crucible.temperature
                crucible.heat!(rate)

                {
                  heated:      true,
                  crucible_id: crucible_id,
                  before:      before.round(10),
                  after:       crucible.temperature.round(10),
                  label:       crucible.temperature_label,
                  overheated:  crucible.overheated?
                }
              end

              def cool_crucible(crucible_id:, rate: Constants::COOL_RATE)
                crucible = @crucibles[crucible_id]
                return { cooled: false, reason: :not_found } unless crucible

                before = crucible.temperature
                crucible.cool!(rate)

                {
                  cooled:      true,
                  crucible_id: crucible_id,
                  before:      before.round(10),
                  after:       crucible.temperature.round(10),
                  label:       crucible.temperature_label
                }
              end

              def smelt(crucible_id:, alloy_type: nil)
                crucible = @crucibles[crucible_id]
                return { smelted: false, reason: :not_found } unless crucible

                if crucible.overheated?
                  destroy_crucible_contents!(crucible)
                  return { smelted: false, reason: :overheated, crucible_id: crucible_id }
                end

                result = crucible.smelt!(@ores, alloy_type: alloy_type)
                if result[:smelted]
                  @alloy_history << result[:alloy]
                  remove_smelted_ores!(result.dig(:alloy, :source_ore_ids) || [])
                end
                result.merge(crucible_id: crucible_id)
              end

              def cool_all!(rate: Constants::COOL_RATE)
                count = 0
                @crucibles.each_value do |crucible|
                  next if crucible.temperature <= 0.0

                  crucible.cool!(rate)
                  count += 1
                end
                { cooled: count, total: @crucibles.size }
              end

              def purest_ores(limit: 10)
                @ores.values
                     .sort_by { |o| -o.purity }
                     .first(limit)
                     .map(&:to_h)
              end

              def hottest_crucibles(limit: 10)
                @crucibles.values
                          .sort_by { |c| -c.temperature }
                          .first(limit)
                          .map(&:to_h)
              end

              def furnace_report
                ore_count      = @ores.size
                crucible_count = @crucibles.size
                alloy_count    = @alloy_history.size
                avg_purity     = ore_count.positive? ? (@ores.values.sum(&:purity) / ore_count).round(10) : 0.0
                avg_temp       = crucible_count.positive? ? (@crucibles.values.sum(&:temperature) / crucible_count).round(10) : 0.0
                optimal_count  = @crucibles.count { |_, c| c.optimal? }
                overheated_count = @crucibles.count { |_, c| c.overheated? }

                {
                  ore_count:            ore_count,
                  crucible_count:       crucible_count,
                  alloy_count:          alloy_count,
                  avg_ore_purity:       avg_purity,
                  avg_temperature:      avg_temp,
                  optimal_crucibles:    optimal_count,
                  overheated_crucibles: overheated_count,
                  ore_capacity:         Constants::MAX_ORES,
                  crucible_capacity:    Constants::MAX_CRUCIBLES
                }
              end

              private

              def destroy_crucible_contents!(crucible)
                crucible.ore_ids.each { |id| @ores.delete(id) }
                crucible.ore_ids.clear
              end

              def remove_smelted_ores!(ore_ids)
                Array(ore_ids).each { |id| @ores.delete(id) }
              end
            end
          end
        end
      end
    end
  end
end
