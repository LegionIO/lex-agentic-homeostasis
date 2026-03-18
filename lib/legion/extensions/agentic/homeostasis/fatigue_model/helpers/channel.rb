# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FatigueModel
          module Helpers
            class Channel
              include Constants

              attr_reader :name, :tasks_processed, :total_depletion, :last_used_at, :created_at, :energy

              def initialize(name:, energy: DEFAULT_ENERGY)
                @name            = name
                @energy          = energy.clamp(ENERGY_FLOOR, ENERGY_CEILING)
                @tasks_processed = 0
                @total_depletion = 0.0
                @last_used_at    = nil
                @created_at      = Time.now.utc
              end

              def deplete!(amount: nil)
                rate   = amount || DEPLETION_RATES.fetch(name, 0.05)
                before = @energy
                @energy = (@energy - rate).clamp(ENERGY_FLOOR, ENERGY_CEILING)
                depleted = before - @energy
                @total_depletion += depleted
                @tasks_processed += 1
                @last_used_at = Time.now.utc
                self
              end

              def recover!(amount: nil)
                rate    = amount || RECOVERY_RATES.fetch(name, 0.06)
                @energy = (@energy + rate).clamp(ENERGY_FLOOR, ENERGY_CEILING)
                self
              end

              def energy_label
                FATIGUE_LABELS.each do |range, label|
                  return label if range.cover?(@energy)
                end
                :unknown
              end

              def needs_rest?
                @energy < REST_THRESHOLD
              end

              def needs_delegation?
                @energy < DELEGATION_THRESHOLD
              end

              def quality_modifier
                @energy.clamp(ENERGY_FLOOR, ENERGY_CEILING)
              end

              def to_h
                {
                  name:             @name,
                  energy:           @energy.round(4),
                  label:            energy_label,
                  tasks_processed:  @tasks_processed,
                  total_depletion:  @total_depletion.round(4),
                  needs_rest:       needs_rest?,
                  needs_delegation: needs_delegation?,
                  quality_modifier: quality_modifier.round(4),
                  last_used_at:     @last_used_at,
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
