# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Pendulum
          module Runners
            module CognitivePendulum
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def create_pendulum(pole_pair:, amplitude: 0.5, period: 10.0, damping: Helpers::Constants::DAMPING_RATE, **)
                unless Helpers::Constants.valid_pole_pair?(pole_pair)
                  return { success: false, error: :invalid_pole_pair, valid_pairs: Helpers::Constants::POLE_PAIRS.keys }
                end

                raise ArgumentError, 'amplitude must be 0.0..1.0' unless amplitude.between?(0.0, 1.0)
                raise ArgumentError, 'period must be positive' unless period.positive?

                if pendulum_engine.count >= Helpers::Constants::MAX_PENDULUMS
                  return { success: false, error: :max_pendulums_reached, max: Helpers::Constants::MAX_PENDULUMS }
                end

                pendulum = pendulum_engine.create_pendulum(
                  pole_pair: pole_pair,
                  amplitude: amplitude,
                  period:    period,
                  damping:   damping
                )

                log.debug("[cognitive_pendulum] created pole_pair=#{pole_pair} id=#{pendulum.id[0..7]}")
                { success: true, pendulum_id: pendulum.id, pole_pair: pole_pair, amplitude: pendulum.amplitude }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def swing(pendulum_id:, force: 0.0, **)
                result = pendulum_engine.swing(pendulum_id, force: force)
                unless result
                  log.debug("[cognitive_pendulum] swing failed: #{pendulum_id[0..7]} not found")
                  return { success: false, error: :not_found }
                end

                log.debug("[cognitive_pendulum] swing id=#{pendulum_id[0..7]} position=#{result.current_position.round(4)}")
                { success: true, pendulum_id: pendulum_id, current_position: result.current_position, dominant_pole: result.dominant_pole }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def damp_all(**)
                pendulum_engine.damp_all!
                count = pendulum_engine.count
                log.debug("[cognitive_pendulum] damped all (#{count} pendulums)")
                { success: true, damped: count }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def check_resonance(frequency:, **)
                return { success: false, error: :invalid_frequency, message: 'frequency must be positive' } unless frequency.to_f.positive?

                resonant_ids = pendulum_engine.check_resonance(frequency.to_f)
                log.debug("[cognitive_pendulum] resonance check frequency=#{frequency} matches=#{resonant_ids.size}")
                { success: true, frequency: frequency, resonant_pendulum_ids: resonant_ids, count: resonant_ids.size }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def get_dominant_pole(pendulum_id:, **)
                pole = pendulum_engine.dominant_pole(pendulum_id)
                if pole.nil?
                  log.debug("[cognitive_pendulum] dominant_pole failed: #{pendulum_id[0..7]} not found")
                  return { success: false, error: :not_found }
                end

                log.debug("[cognitive_pendulum] dominant_pole id=#{pendulum_id[0..7]} pole=#{pole}")
                { success: true, pendulum_id: pendulum_id, dominant_pole: pole }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def most_active(limit: 5, **)
                pendulums = pendulum_engine.most_active(limit: limit)
                log.debug("[cognitive_pendulum] most_active limit=#{limit} found=#{pendulums.size}")
                { success: true, pendulums: pendulums.map(&:to_h), count: pendulums.size }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def most_damped(limit: 5, **)
                pendulums = pendulum_engine.most_damped(limit: limit)
                log.debug("[cognitive_pendulum] most_damped limit=#{limit} found=#{pendulums.size}")
                { success: true, pendulums: pendulums.map(&:to_h), count: pendulums.size }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def pendulum_report(**)
                report = pendulum_engine.pendulum_report
                log.debug("[cognitive_pendulum] report total=#{report[:total]}")
                { success: true, report: report }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              def get_pendulum(pendulum_id:, **)
                p = pendulum_engine.get(pendulum_id)
                p ? { success: true, pendulum: p.to_h } : { success: false, error: :not_found }
              rescue ArgumentError => e
                { success: false, error: :argument_error, message: e.message }
              end

              private

              def pendulum_engine
                @pendulum_engine ||= Helpers::PendulumEngine.new
              end
            end
          end
        end
      end
    end
  end
end
