# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module NeuralOscillation
          module Helpers
            class OscillationNetwork
              include Constants

              attr_reader :oscillators, :couplings

              def initialize
                @oscillators = {}
                @couplings   = []
                @history     = []
              end

              def add_oscillator(id:, domain: :general)
                return @oscillators[id] if @oscillators.key?(id)
                return nil if @oscillators.size >= MAX_OSCILLATORS

                @oscillators[id] = Oscillator.new(id: id, domain: domain)
              end

              def activate_band(oscillator_id:, band:, amount: DEFAULT_POWER)
                osc = @oscillators[oscillator_id]
                return nil unless osc

                osc.activate(band: band, amount: amount)
                propagate_activation(oscillator_id, band, amount)
                osc
              end

              def suppress_band(oscillator_id:, band:, amount: DEFAULT_POWER)
                osc = @oscillators[oscillator_id]
                return nil unless osc

                osc.suppress(band: band, amount: amount)
                osc
              end

              def couple(oscillator_a:, oscillator_b:, band:)
                return nil unless @oscillators.key?(oscillator_a) && @oscillators.key?(oscillator_b)
                return nil if oscillator_a == oscillator_b

                existing = find_coupling(oscillator_a, oscillator_b, band)
                if existing
                  existing.strengthen
                  return existing
                end

                return nil if @couplings.size >= MAX_COUPLINGS

                c = Coupling.new(oscillator_a: oscillator_a, oscillator_b: oscillator_b, band: band)
                @couplings << c
                c
              end

              def decouple(oscillator_a:, oscillator_b:, band:)
                idx = @couplings.index { |c| c.key == [[oscillator_a, oscillator_b].sort, band].flatten }
                return false unless idx

                @couplings.delete_at(idx)
                true
              end

              def global_rhythm
                return nil if @oscillators.empty?

                best_band, best_power = aggregate_band_powers.max_by { |_, v| v }
                best_power&.positive? ? best_band : nil
              end

              def synchrony_for(band:)
                relevant = @couplings.select { |c| c.band == band && c.synchronized? }
                return 0.0 if relevant.empty?

                relevant.sum(&:strength) / relevant.size
              end

              def network_synchrony
                return 0.0 if @couplings.empty?

                synced = @couplings.count(&:synchronized?)
                synced.to_f / @couplings.size
              end

              def cognitive_state
                rhythm = global_rhythm
                return :idle unless rhythm

                COGNITIVE_STATES.fetch(rhythm, :unknown)
              end

              def desynchronize(band:)
                @couplings.select { |c| c.band == band }.each do |c|
                  c.strength = [c.strength * 0.5, 0.0].max
                end
                @oscillators.each_value { |osc| osc.suppress(band: band, amount: 0.1) }
              end

              def tick
                @oscillators.each_value do |osc|
                  osc.advance_phase
                  osc.decay
                end
                @couplings.each(&:decay)
                @couplings.reject!(&:weak?)
                record_state
              end

              def oscillators_in_band(band:)
                @oscillators.values.select { |o| o.dominant_band == band }.map(&:to_h)
              end

              def couplings_for(oscillator_id:)
                @couplings.select { |c| c.involves?(oscillator_id) }.map(&:to_h)
              end

              def to_h
                {
                  oscillator_count:  @oscillators.size,
                  coupling_count:    @couplings.size,
                  global_rhythm:     global_rhythm,
                  cognitive_state:   cognitive_state,
                  network_synchrony: network_synchrony.round(4),
                  band_powers:       aggregate_band_powers,
                  history_size:      @history.size
                }
              end

              private

              def find_coupling(osc_a, osc_b, band)
                sorted = [osc_a, osc_b].sort
                @couplings.find { |c| c.key == [sorted, band].flatten }
              end

              def propagate_activation(source_id, band, amount)
                @couplings.select { |c| c.involves?(source_id) && c.band == band }.each do |c|
                  partner_id = c.partner_of(source_id)
                  partner = @oscillators[partner_id]
                  next unless partner

                  propagated = amount * c.strength * 0.3
                  partner.activate(band: band, amount: propagated) if propagated > 0.01
                end
              end

              def aggregate_band_powers
                result = BANDS.to_h { |b| [b, 0.0] }
                return result if @oscillators.empty?

                @oscillators.each_value { |osc| BANDS.each { |b| result[b] += osc.power(b) } }
                result.transform_values { |v| (v / @oscillators.size).round(4) }
              end

              def record_state
                @history << { at: Time.now.utc, rhythm: global_rhythm, synchrony: network_synchrony.round(4) }
                @history.shift while @history.size > MAX_HISTORY
              end
            end
          end
        end
      end
    end
  end
end
