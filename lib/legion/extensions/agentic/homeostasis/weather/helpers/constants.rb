# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weather
          module Helpers
            module Constants
              FRONT_TYPES      = %i[warm cold occluded stationary].freeze
              CONDITION_TYPES  = %i[clear cloudy foggy stormy lightning blizzard].freeze

              MAX_FRONTS = 100
              MAX_STORMS = 50

              PRESSURE_CHANGE_RATE = 0.05
              DISSIPATION_RATE     = 0.03

              # Range-based severity label lookup — ordered from highest to lowest
              SEVERITY_LABELS = [
                { range: (0.9..1.0),   label: 'catastrophic' },
                { range: (0.75..0.9),  label: 'severe' },
                { range: (0.55..0.75), label: 'moderate' },
                { range: (0.35..0.55), label: 'mild' },
                { range: (0.15..0.35), label: 'light' },
                { range: (0.0..0.15),  label: 'calm' }
              ].freeze

              # Range-based clarity label lookup — ordered from highest to lowest
              CLARITY_LABELS = [
                { range: (0.85..1.0),   label: 'crystal' },
                { range: (0.65..0.85),  label: 'clear' },
                { range: (0.45..0.65),  label: 'hazy' },
                { range: (0.25..0.45),  label: 'murky' },
                { range: (0.0..0.25),   label: 'opaque' }
              ].freeze

              def self.label_for(table, value)
                clamped = value.clamp(0.0, 1.0)
                entry = table.find { |e| e[:range].cover?(clamped) }
                entry ? entry[:label] : table.last[:label]
              end
            end
          end
        end
      end
    end
  end
end
