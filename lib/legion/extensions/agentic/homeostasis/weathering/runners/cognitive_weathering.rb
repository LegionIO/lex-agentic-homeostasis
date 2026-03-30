# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weathering
          module Runners
            module CognitiveWeathering
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def apply_stressor(description:, stressor_type: :cognitive_overload, intensity: 0.5,
                                 duration: 3600, domain: nil, **)
                stressor = Helpers::Stressor.new(
                  description:   description,
                  stressor_type: stressor_type,
                  intensity:     intensity,
                  duration:      duration,
                  domain:        domain
                )

                result = weathering_engine.apply_stressor(stressor)
                log.debug("[cognitive_weathering] stressor applied: type=#{stressor_type} " \
                          "intensity=#{intensity} impact=#{stressor.cumulative_impact.round(4)} " \
                          "integrity=#{result[:integrity].round(4)} fragile=#{result[:fragile]}")
                result.merge(stressor: stressor.to_h)
              end

              def recover(amount: 1.0, **)
                result = weathering_engine.recover!(amount)
                log.debug("[cognitive_weathering] recovery: amount=#{amount} integrity=#{result[:integrity].round(4)}")
                result
              end

              def rest(amount: 1.0, **)
                result = weathering_engine.rest!(amount)
                log.debug("[cognitive_weathering] rest: amount=#{amount} integrity=#{result[:integrity].round(4)}")
                result
              end

              def weathering_report(**)
                report = weathering_engine.weathering_report
                log.debug("[cognitive_weathering] report: integrity=#{report[:integrity_label]} " \
                          "capacity=#{report[:effective_capacity].round(4)} " \
                          "stressors=#{report[:stressor_count]}")
                report
              end

              def integrity_status(**)
                engine = weathering_engine
                {
                  integrity:          engine.integrity.round(10),
                  integrity_label:    Helpers::Constants.integrity_label(engine.integrity),
                  tempering_level:    engine.tempering_level.round(10),
                  weathering_label:   Helpers::Constants.weathering_label(engine.tempering_level),
                  effective_capacity: engine.effective_capacity,
                  fragile:            engine.fragile?,
                  breaking:           engine.breaking?
                }
              end

              private

              def weathering_engine
                @weathering_engine ||= Helpers::WeatheringEngine.new
              end
            end
          end
        end
      end
    end
  end
end
