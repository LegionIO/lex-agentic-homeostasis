# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Pendulum
          module Helpers
            module Constants
              POLE_PAIRS = {
                certainty_doubt:      %i[certainty doubt],
                focus_diffusion:      %i[focus diffusion],
                analysis_intuition:   %i[analysis intuition],
                approach_avoidance:   %i[approach avoidance],
                convergent_divergent: %i[convergent divergent]
              }.freeze

              DAMPING_RATE = 0.01

              MAX_PENDULUMS = 100

              AMPLITUDE_LABELS = {
                (0.0..0.2) => :minimal,
                (0.2..0.4) => :low,
                (0.4..0.6) => :moderate,
                (0.6..0.8) => :high,
                (0.8..1.0) => :maximal
              }.freeze

              module_function

              def valid_pole_pair?(pole_pair)
                POLE_PAIRS.key?(pole_pair)
              end

              def amplitude_label(amplitude)
                clamped = amplitude.clamp(0.0, 1.0)
                AMPLITUDE_LABELS.each do |range, label|
                  return label if range.cover?(clamped)
                end
                :maximal
              end
            end
          end
        end
      end
    end
  end
end
