# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Cocoon
          module Helpers
            module Constants
              MAX_COCOONS      = 100
              MATURITY_RATE    = 0.1
              PREMATURE_PENALTY = 0.5

              GESTATION_STAGES = %i[encapsulating developing transforming ready emerged].freeze

              COCOON_TYPES = %i[silk chrysalis shell pod web].freeze

              PROTECTION_BY_TYPE = {
                silk:      0.6,
                chrysalis: 0.8,
                shell:     0.9,
                pod:       0.7,
                web:       0.5
              }.freeze

              MATURITY_LABELS = {
                (0.9..)     => :fully_gestated,
                (0.7...0.9) => :nearly_ready,
                (0.5...0.7) => :mid_gestation,
                (0.3...0.5) => :early_gestation,
                (0.1...0.3) => :just_encapsulated,
                (..0.1)     => :newly_formed
              }.freeze

              def self.label_for(labels, value)
                labels.each { |range, label| return label if range.cover?(value) }
                :unknown
              end
            end
          end
        end
      end
    end
  end
end
