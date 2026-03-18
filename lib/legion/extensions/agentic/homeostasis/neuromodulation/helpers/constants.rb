# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Neuromodulation
          module Helpers
            module Constants
              MODULATORS         = %i[dopamine serotonin norepinephrine acetylcholine].freeze
              DEFAULT_LEVEL      = 0.5
              LEVEL_FLOOR        = 0.0
              LEVEL_CEILING      = 1.0
              MODULATION_ALPHA   = 0.15
              BASELINE_DRIFT     = 0.01
              MAX_EVENTS         = 200

              OPTIMAL_RANGES = {
                dopamine:       (0.4..0.7),
                serotonin:      (0.4..0.7),
                norepinephrine: (0.3..0.6),
                acetylcholine:  (0.4..0.7)
              }.freeze

              STATE_LABELS = {
                dopamine:       {
                  high:    :surplus,
                  optimal: :optimal,
                  low:     :deficit
                },
                serotonin:      {
                  high:    :surplus,
                  optimal: :optimal,
                  low:     :deficit
                },
                norepinephrine: {
                  high:    :surplus,
                  optimal: :optimal,
                  low:     :deficit
                },
                acetylcholine:  {
                  high:    :surplus,
                  optimal: :optimal,
                  low:     :deficit
                }
              }.freeze
            end
          end
        end
      end
    end
  end
end
