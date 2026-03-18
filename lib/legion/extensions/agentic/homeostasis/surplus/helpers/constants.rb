# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Surplus
          module Helpers
            module Constants
              TOTAL_CAPACITY   = 1.0
              MIN_RESERVE      = 0.1
              SURPLUS_THRESHOLD = 0.15
              REPLENISH_RATE   = 0.05
              DEPLETION_RATE   = 0.08

              SURPLUS_LABELS = {
                abundant: (0.6..1.0),
                moderate: (0.3...0.6),
                scarce:   (0.15...0.3),
                depleted: (0.0...0.15)
              }.freeze

              QUALITY_LABELS = {
                peak:     (0.8..1.0),
                rested:   (0.6...0.8),
                residual: (0.3...0.6),
                degraded: (0.0...0.3)
              }.freeze

              ALLOCATION_TYPES = %i[exploration consolidation speculation maintenance creative].freeze

              module_function

              def surplus_label(amount)
                SURPLUS_LABELS.find { |_label, range| range.cover?(amount) }&.first || :none
              end

              def quality_label(quality)
                QUALITY_LABELS.find { |_label, range| range.cover?(quality) }&.first || :unknown
              end

              def valid_allocation_type?(type)
                ALLOCATION_TYPES.include?(type)
              end

              def clamp(value, min = 0.0, max = 1.0)
                value.clamp(min, max)
              end
            end
          end
        end
      end
    end
  end
end
