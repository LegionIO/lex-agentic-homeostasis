# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Temporal
          module Helpers
            module Constants
              # Time horizons for urgency classification
              URGENCY_HORIZONS = {
                immediate:  10,      # seconds
                short_term: 60,      # 1 minute
                medium:     300,     # 5 minutes
                long_term:  3600,    # 1 hour
                distant:    86_400   # 1 day
              }.freeze

              # Urgency levels (higher = more urgent)
              URGENCY_LEVELS = %i[none low moderate high critical].freeze

              # Deadline urgency thresholds (fraction of remaining time)
              DEADLINE_URGENCY = {
                critical: 0.1,   # <= 10% time remaining
                high:     0.25,  # <= 25%
                moderate: 0.5,   # <= 50%
                low:      0.75,  # <= 75%
                none:     1.0    # > 75%
              }.freeze

              # Temporal pattern types
              PATTERN_TYPES = %i[periodic bursty circadian random].freeze

              # Minimum occurrences to detect a pattern
              MIN_PATTERN_OBSERVATIONS = 5

              # Maximum tracked events per domain
              MAX_EVENTS_PER_DOMAIN = 100

              # Maximum active deadlines
              MAX_DEADLINES = 50

              # Maximum temporal patterns tracked
              MAX_PATTERNS = 30

              # How many recent events to keep globally
              MAX_GLOBAL_EVENTS = 500

              # Coefficient of variation threshold for periodic vs bursty
              PERIODIC_CV_THRESHOLD = 0.3

              # Burst detection: events within this multiplier of mean interval
              BURST_MULTIPLIER = 0.25

              # Subjective time dilation factor ranges
              # When arousal is high, time feels slower (more ticks perceived)
              # When bored/low arousal, time flies
              DILATION_RANGE = { min: 0.5, max: 2.0 }.freeze

              # EMA alpha for subjective time tracking
              SUBJECTIVE_ALPHA = 0.2
            end
          end
        end
      end
    end
  end
end
