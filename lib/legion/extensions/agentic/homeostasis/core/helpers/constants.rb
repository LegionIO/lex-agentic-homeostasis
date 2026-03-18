# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Core
          module Helpers
            module Constants
              # Regulated subsystems and their ideal setpoints (0.0-1.0 scale)
              SETPOINTS = {
                emotional_arousal:   { target: 0.4, tolerance: 0.2 },
                curiosity_intensity: { target: 0.5, tolerance: 0.25 },
                cognitive_load:      { target: 0.6, tolerance: 0.2 },
                memory_health:       { target: 0.7, tolerance: 0.15 },
                prediction_accuracy: { target: 0.6, tolerance: 0.2 },
                trust_stability:     { target: 0.7, tolerance: 0.15 },
                attention_breadth:   { target: 0.5, tolerance: 0.2 }
              }.freeze

              # Regulation gains (how aggressively the system corrects)
              # Higher gain = faster correction but more oscillation risk
              REGULATION_GAIN = {
                emotional_arousal:   0.3,
                curiosity_intensity: 0.2,
                cognitive_load:      0.4,
                memory_health:       0.1,
                prediction_accuracy: 0.15,
                trust_stability:     0.1,
                attention_breadth:   0.2
              }.freeze

              # Allostatic load thresholds
              ALLOSTATIC_LOAD_HEALTHY    = 0.3
              ALLOSTATIC_LOAD_ELEVATED   = 0.6
              ALLOSTATIC_LOAD_CRITICAL   = 0.85
              ALLOSTATIC_DECAY_RATE      = 0.02  # per tick when within tolerance
              ALLOSTATIC_ACCUMULATION    = 0.05  # per tick when outside tolerance

              # Modulation signal bounds
              MAX_DAMPEN  = -0.5  # maximum dampening signal
              MAX_AMPLIFY =  0.5  # maximum amplification signal

              # EMA alpha for setpoint adaptation
              SETPOINT_ADAPTATION_ALPHA = 0.05

              # History limits
              MAX_REGULATION_HISTORY = 100
              MAX_ALLOSTATIC_HISTORY = 200

              # Regulation signal types
              SIGNAL_TYPES = %i[dampen amplify hold].freeze

              # Health classification thresholds
              REGULATION_HEALTH = {
                (0.8..)     => :stable,
                (0.6...0.8) => :compensating,
                (0.4...0.6) => :strained,
                (0.2...0.4) => :dysregulated,
                (..0.2)     => :critical
              }.freeze
            end
          end
        end
      end
    end
  end
end
