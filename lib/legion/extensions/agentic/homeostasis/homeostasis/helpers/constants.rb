# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Homeostasis
          module Helpers
            module Constants
              MAX_VARIABLES = 100

              DEFAULT_SETPOINT = 0.5
              DEFAULT_TOLERANCE = 0.15
              CORRECTION_RATE = 0.08
              DRIFT_RATE = 0.02
              MAX_CORRECTION = 0.3

              BALANCE_LABELS = {
                (0.8..)     => :optimal,
                (0.6...0.8) => :stable,
                (0.4...0.6) => :normal,
                (0.2...0.4) => :strained,
                (..0.2)     => :critical
              }.freeze

              DEVIATION_LABELS = {
                (0.0...0.1)  => :negligible,
                (0.1...0.25) => :minor,
                (0.25...0.5) => :moderate,
                (0.5...0.75) => :major,
                (0.75..1.0)  => :extreme
              }.freeze

              VARIABLE_CATEGORIES = %i[
                general arousal attention cognitive_load emotional_valence
                confidence curiosity fatigue motivation
                social_engagement uncertainty
              ].freeze
            end
          end
        end
      end
    end
  end
end
