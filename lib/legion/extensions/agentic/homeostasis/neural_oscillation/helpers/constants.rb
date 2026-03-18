# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module NeuralOscillation
          module Helpers
            module Constants
              MAX_OSCILLATORS     = 20
              MAX_COUPLINGS       = 100
              MAX_HISTORY         = 200

              POWER_FLOOR         = 0.05
              POWER_DECAY         = 0.02
              DEFAULT_POWER       = 0.3
              DOMINANT_THRESHOLD  = 0.5

              COUPLING_FLOOR      = 0.05
              COUPLING_DECAY      = 0.01
              COUPLING_BOOST      = 0.1
              SYNC_THRESHOLD      = 0.4

              PHASE_INCREMENT     = 0.2

              # Canonical frequency bands (Hz ranges for reference only)
              BANDS = %i[delta theta alpha beta gamma].freeze

              BAND_INFO = {
                delta: { range: '0.5-4 Hz', role: 'deep sleep, unconscious processing' },
                theta: { range: '4-8 Hz', role: 'memory encoding, spatial navigation' },
                alpha: { range: '8-13 Hz', role: 'relaxed awareness, idle inhibition' },
                beta:  { range: '13-30 Hz', role: 'active thinking, motor planning' },
                gamma: { range: '30-100 Hz', role: 'feature binding, consciousness' }
              }.freeze

              # Maps dominant band to cognitive state
              COGNITIVE_STATES = {
                delta: :unconscious,
                theta: :encoding,
                alpha: :resting,
                beta:  :focused,
                gamma: :integrating
              }.freeze

              POWER_LABELS = {
                (0.8..)     => :dominant,
                (0.5...0.8) => :strong,
                (0.3...0.5) => :moderate,
                (0.1...0.3) => :weak,
                (..0.1)     => :silent
              }.freeze
            end
          end
        end
      end
    end
  end
end
