# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module NeuralOscillation
          module Helpers
            class Coupling
              include Constants

              attr_reader :oscillator_a, :oscillator_b, :band
              attr_accessor :strength

              def initialize(oscillator_a:, oscillator_b:, band:, strength: COUPLING_BOOST)
                @oscillator_a = oscillator_a
                @oscillator_b = oscillator_b
                @band         = band
                @strength     = strength.to_f.clamp(0.0, 1.0)
                @created_at   = Time.now.utc
              end

              def key
                [[@oscillator_a, @oscillator_b].sort, @band].flatten
              end

              def strengthen(amount = COUPLING_BOOST)
                @strength = [@strength + amount, 1.0].min
              end

              def decay
                @strength = [@strength - COUPLING_DECAY, 0.0].max
              end

              def weak?
                @strength <= COUPLING_FLOOR
              end

              def synchronized?
                @strength >= SYNC_THRESHOLD
              end

              def involves?(oscillator_id)
                [@oscillator_a, @oscillator_b].include?(oscillator_id)
              end

              def partner_of(oscillator_id)
                return @oscillator_b if @oscillator_a == oscillator_id
                return @oscillator_a if @oscillator_b == oscillator_id

                nil
              end

              def to_h
                {
                  oscillator_a: @oscillator_a,
                  oscillator_b: @oscillator_b,
                  band:         @band,
                  strength:     @strength.round(4),
                  synchronized: synchronized?
                }
              end
            end
          end
        end
      end
    end
  end
end
