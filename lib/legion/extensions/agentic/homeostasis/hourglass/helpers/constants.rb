# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Hourglass
          module Helpers
            module Constants
              GRAIN_TYPES = %i[attention focus patience willpower creativity].freeze
              FLOW_STATES = %i[flowing blocked empty full paused].freeze

              MAX_HOURGLASSES = 100
              MAX_GRAINS      = 500
              FLOW_RATE       = 0.05
              BLOCKAGE_CHANCE = 0.1

              # Range-based urgency label lookup — ordered from most urgent to most relaxed
              URGENCY_LABELS = [
                { range: (0.85..1.0),  label: 'critical' },
                { range: (0.65..0.85), label: 'urgent' },
                { range: (0.40..0.65), label: 'moderate' },
                { range: (0.20..0.40), label: 'low' },
                { range: (0.0..0.20),  label: 'relaxed' }
              ].freeze

              # Range-based fullness label lookup — ordered from most full to most empty
              FULLNESS_LABELS = [
                { range: (0.90..1.0),  label: 'overflowing' },
                { range: (0.65..0.90), label: 'full' },
                { range: (0.35..0.65), label: 'half' },
                { range: (0.10..0.35), label: 'low' },
                { range: (0.0..0.10),  label: 'empty' }
              ].freeze

              def self.label_for(table, value)
                clamped = value.clamp(0.0, 1.0)
                entry = const_get(table).find { |e| e[:range].cover?(clamped) }
                entry ? entry[:label] : 'unknown'
              end
            end
          end
        end
      end
    end
  end
end
