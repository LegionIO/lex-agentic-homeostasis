# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Hourglass
          module Runners
            module CognitiveHourglass
              extend self

              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def create_grain(grain_type: :attention, domain: nil, content: nil, weight: 1.0,
                               engine: nil, **)
                eng   = engine || hourglass_engine
                grain = eng.create_grain(
                  grain_type: grain_type.to_sym,
                  domain:     domain,
                  content:    content,
                  weight:     weight.to_f
                )
                log.debug("[cognitive_hourglass] grain created: type=#{grain_type} domain=#{domain} weight=#{grain.weight}")
                { success: true, grain: grain.to_h }
              rescue ArgumentError => e
                log.error("[cognitive_hourglass] create_grain failed: #{e.message}")
                { success: false, error: e.message }
              end

              def create_hourglass(domain: nil, grain_type: :attention, top_level: 1.0,
                                   neck_width: 0.5, bottom_level: 0.0, engine: nil, **)
                eng        = engine || hourglass_engine
                hourglass  = eng.create_hourglass(
                  domain:       domain,
                  grain_type:   grain_type.to_sym,
                  top_level:    top_level.to_f,
                  neck_width:   neck_width.to_f,
                  bottom_level: bottom_level.to_f
                )
                log.debug("[cognitive_hourglass] hourglass created: id=#{hourglass.id} " \
                          "domain=#{domain} grain_type=#{grain_type} top=#{hourglass.top_level}")
                { success: true, hourglass: hourglass.to_h }
              rescue ArgumentError => e
                log.error("[cognitive_hourglass] create_hourglass failed: #{e.message}")
                { success: false, error: e.message }
              end

              def flow_tick(rate: Helpers::Constants::FLOW_RATE, engine: nil, **)
                eng    = engine || hourglass_engine
                result = eng.flow_tick(rate.to_f)
                log.debug("[cognitive_hourglass] flow_tick: ticked=#{result[:ticked]} " \
                          "expired=#{result[:expired]} blocked=#{result[:blocked]}")
                result.merge(success: true)
              rescue ArgumentError => e
                log.error("[cognitive_hourglass] flow_tick failed: #{e.message}")
                { success: false, error: e.message }
              end

              def flip(hourglass_id:, engine: nil, **)
                eng       = engine || hourglass_engine
                hourglass = eng.flip(hourglass_id)
                log.debug("[cognitive_hourglass] flipped: id=#{hourglass_id} top=#{hourglass.top_level}")
                { success: true, hourglass: hourglass.to_h }
              rescue ArgumentError => e
                log.error("[cognitive_hourglass] flip failed: #{e.message}")
                { success: false, error: e.message }
              end

              def list_hourglasses(engine: nil, **)
                eng  = engine || hourglass_engine
                list = eng.hourglasses.values.map(&:to_h)
                log.debug("[cognitive_hourglass] list_hourglasses: count=#{list.size}")
                { success: true, hourglasses: list, count: list.size }
              rescue ArgumentError => e
                log.error("[cognitive_hourglass] list_hourglasses failed: #{e.message}")
                { success: false, error: e.message }
              end

              def time_status(engine: nil, **)
                eng    = engine || hourglass_engine
                report = eng.flow_report
                log.debug("[cognitive_hourglass] time_status: total=#{report[:total]} " \
                          "flowing=#{report[:flowing]} empty=#{report[:empty]}")
                report.merge(success: true)
              rescue ArgumentError => e
                log.error("[cognitive_hourglass] time_status failed: #{e.message}")
                { success: false, error: e.message }
              end

              private

              def hourglass_engine
                @hourglass_engine ||= Helpers::HourglassEngine.new
              end
            end
          end
        end
      end
    end
  end
end
