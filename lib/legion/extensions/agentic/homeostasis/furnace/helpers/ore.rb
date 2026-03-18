# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Furnace
          module Helpers
            class Ore
              attr_reader :ore_id, :ore_type, :domain, :content, :created_at
              attr_accessor :purity, :impurity

              def initialize(ore_type:, domain:, content:, purity: 0.5, impurity: nil, ore_id: nil)
                unless Constants::ORE_TYPES.include?(ore_type)
                  raise ArgumentError, "unknown ore_type: #{ore_type.inspect}; " \
                                       "must be one of #{Constants::ORE_TYPES.inspect}"
                end

                @ore_id     = ore_id || SecureRandom.uuid
                @ore_type   = ore_type
                @domain     = domain
                @content    = content
                @purity     = purity.clamp(0.0, 1.0)
                @impurity   = (impurity || (1.0 - @purity)).clamp(0.0, 1.0)
                @created_at = Time.now.utc
              end

              def refine!(rate = Constants::HEAT_RATE)
                delta = rate.clamp(0.0, 1.0)
                self.purity   = (purity + delta).clamp(0.0, 1.0)
                self.impurity = (impurity - delta).clamp(0.0, 1.0)
                self
              end

              def contaminate!(rate = Constants::COOL_RATE)
                delta = rate.clamp(0.0, 1.0)
                self.purity   = (purity - delta).clamp(0.0, 1.0)
                self.impurity = (impurity + delta).clamp(0.0, 1.0)
                self
              end

              def pure?
                purity >= 0.8
              end

              def crude?
                purity < 0.3
              end

              def purity_label
                Constants.label_for(Constants::PURITY_LABELS, purity)
              end

              def to_h
                {
                  ore_id:     ore_id,
                  ore_type:   ore_type,
                  domain:     domain,
                  content:    content,
                  purity:     purity.round(10),
                  impurity:   impurity.round(10),
                  pure:       pure?,
                  crude:      crude?,
                  label:      purity_label,
                  created_at: created_at
                }
              end
            end
          end
        end
      end
    end
  end
end
