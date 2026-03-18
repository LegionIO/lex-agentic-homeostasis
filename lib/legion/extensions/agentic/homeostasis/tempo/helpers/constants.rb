# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tempo
          module Helpers
            module Constants
              DEFAULT_TEMPO       = 0.5
              TEMPO_ADJUSTMENT    = 0.05
              MAX_TEMPO_RECORDS   = 300

              TEMPO_LABELS = {
                (0.0..0.2) => :slow,
                (0.2..0.4) => :deliberate,
                (0.4..0.6) => :moderate,
                (0.6..0.8) => :fast,
                (0.8..1.0) => :rapid
              }.freeze

              MISMATCH_LABELS = {
                (0.0..0.1)  => :synchronized,
                (0.1..0.25) => :slightly_off,
                (0.25..0.5) => :mismatched,
                (0.5..1.0)  => :severely_mismatched
              }.freeze
            end
          end
        end
      end
    end
  end
end
