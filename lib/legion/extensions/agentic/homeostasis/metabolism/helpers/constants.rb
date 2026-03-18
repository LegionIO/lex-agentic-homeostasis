# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Metabolism
          module Helpers
            module Constants
              MAX_ENERGY = 1000.0
              RESTING_METABOLIC_RATE = 0.5
              RECOVERY_RATE        = 2.0
              EFFICIENCY_DECAY     = 0.01

              OPERATION_COSTS = {
                perception:       5.0,
                memory_retrieval: 8.0,
                reasoning:        15.0,
                creativity:       20.0,
                decision:         12.0,
                communication:    10.0
              }.freeze

              METABOLIC_STATES = %i[optimal efficient normal strained depleted].freeze

              STATE_THRESHOLDS = {
                optimal:   (0.8..),
                efficient: (0.6...0.8),
                normal:    (0.4...0.6),
                strained:  (0.15...0.4),
                depleted:  (..0.15)
              }.freeze

              module_function

              def label_for(energy_ratio)
                ratio = energy_ratio.clamp(0.0, 1.0)
                STATE_THRESHOLDS.each do |state, range|
                  return state if range.cover?(ratio)
                end
                :depleted
              end
            end
          end
        end
      end
    end
  end
end
