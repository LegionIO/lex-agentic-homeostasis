# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FossilFuel
          module Helpers
            class FuelEngine
              def initialize
                @reserves    = {}
                @combustions = {}
              end

              def create_reserve(fuel_type:, domain:, content:, volume: nil, quality: nil)
                raise ArgumentError, 'reserve limit reached' if @reserves.size >= Constants::MAX_RESERVES

                r = Reserve.new(fuel_type: fuel_type, domain: domain, content: content,
                                volume: volume, quality: quality)
                @reserves[r.id] = r
                r
              end

              def extract(reserve_id:, rate: Constants::EXTRACTION_RATE)
                reserve = fetch_reserve(reserve_id)
                amount  = reserve.extract!(rate: rate)
                { reserve: reserve, extracted: amount }
              end

              def combust(reserve_id:, amount: nil, grade: :crude)
                reserve   = fetch_reserve(reserve_id)
                fuel_amt  = amount || Constants::EXTRACTION_RATE
                extracted = reserve.extract!(rate: fuel_amt)

                raise ArgumentError, 'reserve depleted' if extracted < 0.001

                combustion = Combustion.new(reserve_id:  reserve_id,
                                            fuel_amount: extracted,
                                            grade:       grade,
                                            quality:     reserve.quality)
                @combustions[combustion.id] = combustion
                { combustion: combustion, reserve: reserve }
              end

              def total_energy_released
                @combustions.values.sum(&:energy_released).round(10)
              end

              def reserves_by_type
                counts = Constants::FUEL_TYPES.to_h { |t| [t, 0] }
                @reserves.each_value { |r| counts[r.fuel_type] += 1 }
                counts
              end

              def scarce_reserves
                @reserves.values.select(&:scarce?)
              end

              def depleted_reserves
                @reserves.values.select(&:depleted?)
              end

              def richest(limit: 5)
                @reserves.values.sort_by { |r| -r.volume }.first(limit)
              end

              def fuel_report
                {
                  total_reserves:    @reserves.size,
                  total_combustions: @combustions.size,
                  total_energy:      total_energy_released,
                  by_type:           reserves_by_type,
                  depleted_count:    depleted_reserves.size,
                  scarce_count:      scarce_reserves.size,
                  avg_volume:        avg_metric(:volume),
                  avg_quality:       avg_metric(:quality)
                }
              end

              def all_reserves
                @reserves.values
              end

              def all_combustions
                @combustions.values
              end

              private

              def fetch_reserve(id)
                @reserves.fetch(id) { raise ArgumentError, "reserve not found: #{id}" }
              end

              def avg_metric(attr)
                return 0.0 if @reserves.empty?

                (@reserves.values.sum(&attr) / @reserves.size).round(10)
              end
            end
          end
        end
      end
    end
  end
end
