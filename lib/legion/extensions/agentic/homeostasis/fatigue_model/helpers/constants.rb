# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FatigueModel
          module Helpers
            module Constants
              CHANNELS = %i[attention working_memory decision_making creative social].freeze

              FATIGUE_LABELS = {
                (0.8..)     => :fresh,
                (0.6...0.8) => :alert,
                (0.4...0.6) => :tired,
                (0.2...0.4) => :fatigued,
                (..0.2)     => :exhausted
              }.freeze

              DEPLETION_RATES = {
                attention:       0.05,
                working_memory:  0.04,
                decision_making: 0.06,
                creative:        0.03,
                social:          0.04
              }.freeze

              RECOVERY_RATES = {
                attention:       0.08,
                working_memory:  0.06,
                decision_making: 0.04,
                creative:        0.10,
                social:          0.07
              }.freeze

              MAX_HISTORY    = 500
              ENERGY_FLOOR   = 0.0
              ENERGY_CEILING = 1.0
              DEFAULT_ENERGY = 1.0

              REST_THRESHOLD       = 0.3
              DELEGATION_THRESHOLD = 0.2
            end
          end
        end
      end
    end
  end
end
