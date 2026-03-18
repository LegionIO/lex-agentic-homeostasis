# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Furnace
          module Helpers
            class Crucible
              attr_reader :crucible_id, :capacity, :ore_ids, :created_at
              attr_accessor :temperature

              def initialize(capacity: 10, crucible_id: nil, temperature: 0.0)
                @crucible_id = crucible_id || SecureRandom.uuid
                @capacity    = capacity.clamp(1, 100)
                @temperature = temperature.clamp(0.0, 1.0)
                @ore_ids     = []
                @created_at  = Time.now.utc
              end

              def heat!(rate = Constants::HEAT_RATE)
                self.temperature = (temperature + rate.clamp(0.0, 1.0)).clamp(0.0, 1.0)
                self
              end

              def cool!(rate = Constants::COOL_RATE)
                self.temperature = (temperature - rate.clamp(0.0, 1.0)).clamp(0.0, 1.0)
                self
              end

              def load_ore(ore_id)
                return { loaded: false, reason: :at_capacity } if ore_ids.size >= capacity
                return { loaded: false, reason: :already_loaded } if ore_ids.include?(ore_id)

                ore_ids << ore_id
                { loaded: true, ore_id: ore_id, count: ore_ids.size }
              end

              def unload_ore(ore_id)
                removed = ore_ids.delete(ore_id)
                { unloaded: removed ? true : false, ore_id: ore_id, count: ore_ids.size }
              end

              def smelt!(ore_store, alloy_type: nil)
                return { smelted: false, reason: :temperature_too_low } unless temperature >= Constants::SMELT_THRESHOLD
                return { smelted: false, reason: :no_ores } if ore_ids.empty?

                ores = ore_ids.filter_map { |id| ore_store[id] }
                return { smelted: false, reason: :no_ores_found } if ores.empty?

                alloy = build_alloy(ores, alloy_type)
                ore_ids.clear
                { smelted: true, alloy: alloy }
              end

              def overheated?
                temperature >= Constants::DESTROY_THRESHOLD
              end

              def optimal?
                temperature >= Constants::SMELT_THRESHOLD && temperature < Constants::DESTROY_THRESHOLD
              end

              def temperature_label
                Constants.label_for(Constants::TEMPERATURE_LABELS, temperature)
              end

              def full?
                ore_ids.size >= capacity
              end

              def to_h
                {
                  crucible_id:       crucible_id,
                  temperature:       temperature.round(10),
                  capacity:          capacity,
                  ore_count:         ore_ids.size,
                  ore_ids:           ore_ids.dup,
                  overheated:        overheated?,
                  optimal:           optimal?,
                  temperature_label: temperature_label,
                  created_at:        created_at
                }
              end

              private

              def build_alloy(ores, alloy_type)
                stats = compute_alloy_stats(ores)
                {
                  alloy_id:             SecureRandom.uuid,
                  alloy_type:           alloy_type || infer_alloy_type(ores),
                  domain:               stats[:domain],
                  purity:               stats[:refined_purity].round(10),
                  impurity:             stats[:avg_impurity].round(10),
                  ore_count:            ores.size,
                  source_ore_ids:       ore_ids.dup,
                  content:              stats[:content],
                  temperature_at_smelt: temperature,
                  created_at:           Time.now.utc
                }
              end

              def compute_alloy_stats(ores)
                avg_purity     = ores.sum(&:purity).to_f / ores.size
                avg_impurity   = ores.sum(&:impurity).to_f / ores.size
                temp_bonus     = temperature - Constants::SMELT_THRESHOLD
                refined_purity = (avg_purity + (temp_bonus * 0.2)).clamp(0.0, 1.0)
                {
                  avg_impurity:   avg_impurity,
                  refined_purity: refined_purity,
                  domain:         ores.map(&:domain).tally.max_by { |_, n| n }&.first,
                  content:        ores.map(&:content).compact.join(' + ')
                }
              end

              def infer_alloy_type(ores)
                type_counts = ores.map(&:ore_type).tally
                dominant    = type_counts.max_by { |_, n| n }&.first

                case dominant
                when :experience    then :wisdom
                when :observation   then :insight
                when :hypothesis    then :theory
                when :data          then :synthesis
                when :intuition     then :expertise
                else Constants::ALLOY_TYPES.first
                end
              end
            end
          end
        end
      end
    end
  end
end
