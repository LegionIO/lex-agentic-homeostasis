# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FossilFuel
          module Helpers
            class Reserve
              attr_reader :id, :fuel_type, :domain, :content,
                          :discovered_at
              attr_accessor :volume, :quality

              def initialize(fuel_type:, domain:, content:,
                             volume: nil, quality: nil)
                validate_fuel!(fuel_type)
                @id            = SecureRandom.uuid
                @fuel_type     = fuel_type.to_sym
                @domain        = domain.to_sym
                @content       = content.to_s
                @volume        = (volume || 0.8).to_f.clamp(0.0, 1.0).round(10)
                @quality       = (quality || 0.5).to_f.clamp(0.0, 1.0).round(10)
                @discovered_at = Time.now.utc
              end

              def extract!(rate: Constants::EXTRACTION_RATE)
                amount  = [rate.abs, @volume].min
                @volume = (@volume - amount).clamp(0.0, 1.0).round(10)
                amount.round(10)
              end

              def depleted?
                @volume < 0.01
              end

              def scarce?
                @volume < Constants::DEPLETION_WARNING
              end

              def abundant?
                @volume >= 0.8
              end

              def reserve_label
                Constants.label_for(Constants::RESERVE_LABELS, @volume)
              end

              def to_h
                {
                  id:            @id,
                  fuel_type:     @fuel_type,
                  domain:        @domain,
                  content:       @content,
                  volume:        @volume,
                  reserve_label: reserve_label,
                  quality:       @quality,
                  depleted:      depleted?,
                  scarce:        scarce?,
                  abundant:      abundant?,
                  discovered_at: @discovered_at
                }
              end

              private

              def validate_fuel!(val)
                return if Constants::FUEL_TYPES.include?(val.to_sym)

                raise ArgumentError,
                      "unknown fuel type: #{val.inspect}; " \
                      "must be one of #{Constants::FUEL_TYPES.inspect}"
              end
            end
          end
        end
      end
    end
  end
end
