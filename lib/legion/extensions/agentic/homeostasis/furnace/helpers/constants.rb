# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Furnace
          module Helpers
            module Constants
              ORE_TYPES   = %i[experience observation hypothesis data intuition].freeze
              ALLOY_TYPES = %i[insight wisdom expertise synthesis theory].freeze

              MAX_ORES      = 500
              MAX_CRUCIBLES = 50

              HEAT_RATE  = 0.1
              COOL_RATE  = 0.05

              SMELT_THRESHOLD   = 0.6
              DESTROY_THRESHOLD = 0.95

              PURITY_LABELS = {
                (0.8..1.0)  => :refined,
                (0.6...0.8) => :processed,
                (0.4...0.6) => :raw,
                (0.2...0.4) => :crude,
                (0.0...0.2) => :impure
              }.freeze

              TEMPERATURE_LABELS = {
                (0.9..1.0)  => :white_hot,
                (0.7...0.9) => :red_hot,
                (0.5...0.7) => :warm,
                (0.3...0.5) => :cool,
                (0.0...0.3) => :cold
              }.freeze

              def self.label_for(table, value)
                clamped = value.clamp(0.0, 1.0)
                table.each do |range, label|
                  return label if range.cover?(clamped)
                end
                table.values.last
              end
            end
          end
        end
      end
    end
  end
end
