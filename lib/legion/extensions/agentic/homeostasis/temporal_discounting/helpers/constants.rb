# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module TemporalDiscounting
          module Helpers
            DEFAULT_DISCOUNT_RATE = 0.1
            MIN_DISCOUNT_RATE     = 0.01
            MAX_DISCOUNT_RATE     = 1.0
            MAX_REWARDS           = 500
            DEFAULT_DELAY         = 1.0

            IMPULSIVITY_LABELS = {
              (0.0...0.05)  => :patient,
              (0.05...0.15) => :moderate,
              (0.15...0.3)  => :impulsive,
              (0.3...0.6)   => :very_impulsive,
              (0.6..1.0)    => :extreme
            }.freeze

            VALUE_LABELS = {
              (0.8..)     => :full_value,
              (0.6...0.8) => :high_value,
              (0.4...0.6) => :moderate_value,
              (0.2...0.4) => :low_value,
              (..0.2)     => :negligible
            }.freeze
          end
        end
      end
    end
  end
end
