# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weathering
          module Helpers
            module Constants
              MAX_STRESSORS         = 200
              MAX_EVENTS            = 500

              DEFAULT_INTEGRITY     = 1.0
              WEAR_RATE             = 0.02
              RECOVERY_RATE         = 0.01
              TEMPERING_RATE        = 0.03

              TEMPERING_THRESHOLD   = 0.4
              CRITICAL_INTEGRITY    = 0.3
              BREAKDOWN_INTEGRITY   = 0.1

              STRESSOR_TYPES = %i[
                cognitive_overload
                emotional_strain
                decision_fatigue
                conflict_exposure
                uncertainty
                time_pressure
                monotony
                complexity
              ].freeze

              INTEGRITY_LABELS = [
                { range: (0.8..1.0),  label: 'pristine' },
                { range: (0.6...0.8), label: 'strong'   },
                { range: (0.4...0.6), label: 'worn'     },
                { range: (0.2...0.4), label: 'fragile'  },
                { range: (0.0...0.2), label: 'breaking' }
              ].freeze

              WEATHERING_LABELS = [
                { range: (0.7..1.0),  label: 'tempered' },
                { range: (0.5...0.7), label: 'resilient'  },
                { range: (0.3...0.5), label: 'stable'     },
                { range: (0.1...0.3), label: 'weathered'  },
                { range: (0.0...0.1), label: 'eroded'     }
              ].freeze

              module_function

              def integrity_label(integrity)
                entry = INTEGRITY_LABELS.find { |e| e[:range].cover?(integrity) }
                entry ? entry[:label] : 'breaking'
              end

              def weathering_label(tempering_level)
                entry = WEATHERING_LABELS.find { |e| e[:range].cover?(tempering_level) }
                entry ? entry[:label] : 'eroded'
              end
            end
          end
        end
      end
    end
  end
end
