# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FossilFuel
          module Helpers
            module Constants
              FUEL_TYPES = %i[coal oil gas peat shale].freeze

              GRADES = %i[crude refined premium synthetic].freeze

              MAX_RESERVES = 200
              MAX_REFINERIES = 20
              EXTRACTION_RATE = 0.05
              COMBUSTION_EFFICIENCY = 0.7
              DEPLETION_WARNING = 0.2

              RESERVE_LABELS = [
                [(0.8..),      :abundant],
                [(0.6...0.8),  :healthy],
                [(0.4...0.6),  :moderate],
                [(0.2...0.4),  :scarce],
                [..0.2,        :critical]
              ].freeze

              ENERGY_LABELS = [
                [(0.8..),      :explosive],
                [(0.6...0.8),  :powerful],
                [(0.4...0.6),  :steady],
                [(0.2...0.4),  :weak],
                [..0.2,        :exhausted]
              ].freeze

              def self.label_for(table, value)
                table.each { |range, label| return label if range.cover?(value) }
                table.last.last
              end
            end
          end
        end
      end
    end
  end
end
