# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tectonics
          module Helpers
            module Constants
              MAX_PLATES            = 50
              MAX_QUAKES            = 200
              BOUNDARY_TYPES        = %i[convergent divergent transform].freeze
              MIN_DRIFT_RATE        = 0.001
              MAX_DRIFT_RATE        = 0.05
              COLLISION_THRESHOLD   = 0.2
              SUBDUCTION_RATIO      = 0.7
              AFTERSHOCK_DECAY      = 0.3
              STRESS_QUAKE_TRIGGER  = 1.0

              PLATE_STATES = %i[active subducted dormant].freeze

              MAGNITUDE_LABELS = {
                (0.0...1.0)             => :micro,
                (1.0...2.0)             => :minor,
                (2.0...3.0)             => :light,
                (3.0...4.0)             => :moderate,
                (4.0...5.0)             => :strong,
                (5.0...Float::INFINITY) => :great
              }.freeze

              def label_for(magnitude)
                MAGNITUDE_LABELS.find { |range, _| range.cover?(magnitude) }&.last || :unknown
              end
            end
          end
        end
      end
    end
  end
end
