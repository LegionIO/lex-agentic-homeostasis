# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module NeuralOscillation
          module Runners
            module NeuralOscillation
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def add_oscillator(id:, domain: :general, **)
                Legion::Logging.debug "[neural_oscillation] add: id=#{id} domain=#{domain}"
                osc = network.add_oscillator(id: id, domain: domain)
                if osc
                  { success: true, oscillator: osc.to_h }
                else
                  { success: false, reason: :limit_reached }
                end
              end

              def activate_band(oscillator_id:, band:, amount: nil, **)
                amt = amount || Helpers::Constants::DEFAULT_POWER
                Legion::Logging.debug "[neural_oscillation] activate: osc=#{oscillator_id} band=#{band}"
                osc = network.activate_band(oscillator_id: oscillator_id, band: band.to_sym, amount: amt)
                if osc
                  { success: true, oscillator: osc.to_h }
                else
                  { success: false, reason: :not_found }
                end
              end

              def suppress_band(oscillator_id:, band:, amount: nil, **)
                amt = amount || Helpers::Constants::DEFAULT_POWER
                Legion::Logging.debug "[neural_oscillation] suppress: osc=#{oscillator_id} band=#{band}"
                osc = network.suppress_band(oscillator_id: oscillator_id, band: band.to_sym, amount: amt)
                if osc
                  { success: true, oscillator: osc.to_h }
                else
                  { success: false, reason: :not_found }
                end
              end

              def couple_oscillators(oscillator_a:, oscillator_b:, band:, **)
                Legion::Logging.debug "[neural_oscillation] couple: #{oscillator_a}<->#{oscillator_b} band=#{band}"
                c = network.couple(oscillator_a: oscillator_a, oscillator_b: oscillator_b, band: band.to_sym)
                if c
                  { success: true, coupling: c.to_h }
                else
                  { success: false, reason: :invalid_pair }
                end
              end

              def decouple_oscillators(oscillator_a:, oscillator_b:, band:, **)
                Legion::Logging.debug "[neural_oscillation] decouple: #{oscillator_a}<->#{oscillator_b}"
                removed = network.decouple(oscillator_a: oscillator_a, oscillator_b: oscillator_b, band: band.to_sym)
                { success: removed }
              end

              def global_rhythm(**)
                rhythm = network.global_rhythm
                state = network.cognitive_state
                Legion::Logging.debug "[neural_oscillation] rhythm=#{rhythm} state=#{state}"
                { success: true, rhythm: rhythm, cognitive_state: state, synchrony: network.network_synchrony.round(4) }
              end

              def synchrony_for_band(band:, **)
                level = network.synchrony_for(band: band.to_sym)
                { success: true, band: band.to_sym, synchrony: level.round(4) }
              end

              def desynchronize_band(band:, **)
                Legion::Logging.debug "[neural_oscillation] desync band=#{band}"
                network.desynchronize(band: band.to_sym)
                { success: true, band: band.to_sym }
              end

              def update_neural_oscillations(**)
                Legion::Logging.debug '[neural_oscillation] tick'
                network.tick
                { success: true, rhythm: network.global_rhythm, oscillators: network.oscillators.size }
              end

              def neural_oscillation_stats(**)
                Legion::Logging.debug '[neural_oscillation] stats'
                { success: true, stats: network.to_h }
              end

              private

              def network
                @network ||= Helpers::OscillationNetwork.new
              end
            end
          end
        end
      end
    end
  end
end
