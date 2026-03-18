# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Rhythm
          module Helpers
            module Constants
              ULTRADIAN_PERIOD  = 5400
              CIRCADIAN_PERIOD  = 86_400
              MIN_AMPLITUDE     = 0.0
              MAX_AMPLITUDE     = 1.0
              DEFAULT_PHASE_OFFSET = 0.0
              MAX_RHYTHMS       = 20
              MAX_HISTORY       = 200

              RHYTHM_TYPES = %i[ultradian circadian custom].freeze

              COGNITIVE_DIMENSIONS = %i[alertness creativity focus analytical social emotional].freeze

              PHASE_LABELS = {
                (0.0...0.25) => :rising,
                (0.25...0.5) => :peak,
                (0.5...0.75) => :falling,
                (0.75..1.0)  => :trough
              }.freeze

              AMPLITUDE_LABELS = {
                (0.8..)     => :high,
                (0.6...0.8) => :moderate_high,
                (0.4...0.6) => :moderate,
                (0.2...0.4) => :moderate_low,
                (..0.2)     => :low
              }.freeze
            end
          end
        end
      end
    end
  end
end
