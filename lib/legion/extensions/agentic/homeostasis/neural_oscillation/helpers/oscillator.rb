# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module NeuralOscillation
          module Helpers
            class Oscillator
              include Constants

              BAND_SPEEDS = { delta: 1.0, theta: 2.0, alpha: 3.0, beta: 4.0, gamma: 6.0 }.freeze

              attr_reader :id, :domain

              def initialize(id:, domain: :general)
                @id     = id
                @domain = domain
                @powers = BANDS.to_h { |b| [b, 0.0] }
                @phases = BANDS.to_h { |b| [b, rand * 2 * Math::PI] }
              end

              def power(band)
                @powers.fetch(band, 0.0)
              end

              def phase(band)
                @phases.fetch(band, 0.0)
              end

              def activate(band:, amount: DEFAULT_POWER)
                return unless BANDS.include?(band)

                @powers[band] = [@powers[band] + amount, 1.0].min
              end

              def suppress(band:, amount: DEFAULT_POWER)
                return unless BANDS.include?(band)

                @powers[band] = [@powers[band] - amount, 0.0].max
              end

              def dominant_band
                best = @powers.max_by { |_, v| v }
                return nil unless best && best[1] > POWER_FLOOR

                best[0]
              end

              def dominant?
                band = dominant_band
                band && @powers[band] >= DOMINANT_THRESHOLD
              end

              def advance_phase
                BANDS.each do |band|
                  next if @powers[band] <= POWER_FLOOR

                  @phases[band] = (@phases[band] + (PHASE_INCREMENT * band_speed(band))) % (2 * Math::PI)
                end
              end

              def phase_difference(other, band:)
                diff = (@phases[band] - other.phase(band)).abs % (2 * Math::PI)
                diff > Math::PI ? (2 * Math::PI) - diff : diff
              end

              def synchrony_with(other, band:)
                diff = phase_difference(other, band: band)
                1.0 - (diff / Math::PI)
              end

              def decay
                BANDS.each { |b| @powers[b] = [@powers[b] - POWER_DECAY, 0.0].max }
              end

              def power_label(band)
                val = @powers.fetch(band, 0.0)
                POWER_LABELS.each { |range, lbl| return lbl if range.cover?(val) }
                :silent
              end

              def to_h
                {
                  id:            @id,
                  domain:        @domain,
                  powers:        @powers.transform_values { |v| v.round(4) },
                  dominant_band: dominant_band,
                  dominant:      dominant?,
                  phases:        @phases.transform_values { |v| v.round(4) }
                }
              end

              private

              def band_speed(band)
                BAND_SPEEDS.fetch(band, 1.0)
              end
            end
          end
        end
      end
    end
  end
end
