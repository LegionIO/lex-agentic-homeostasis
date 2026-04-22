# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FatigueModel
          module Runners
            module CognitiveFatigueModel
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def process_cognitive_task(channel_name:, **)
                result = engine.process_task(channel_name: channel_name)
                log.debug("[cognitive_fatigue] task: channel=#{channel_name} energy=#{result[:energy]} label=#{result[:label]}")
                { channel: result, overall_fatigue: engine.overall_fatigue.round(4) }
              end

              def rest_cognitive_channel(channel_name:, **)
                result = engine.rest_channel(channel_name: channel_name)
                log.debug("[cognitive_fatigue] rest channel: channel=#{channel_name} energy=#{result[:energy]}")
                { channel: result }
              end

              def rest_all_channels(**)
                result = engine.rest_all
                log.debug("[cognitive_fatigue] rest all: overall=#{result[:overall_fatigue]}")
                result
              end

              def channel_fatigue_status(channel_name:, **)
                result = engine.channel_status(channel_name: channel_name)
                log.debug("[cognitive_fatigue] status: channel=#{channel_name} energy=#{result[:energy]}")
                result
              end

              def overall_fatigue_report(**)
                fatigue = engine.overall_fatigue
                most_fatigued = engine.most_fatigued_channel
                log.debug("[cognitive_fatigue] overall: fatigue=#{fatigue.round(4)}")
                {
                  overall_fatigue:       fatigue.round(4),
                  most_fatigued:         most_fatigued,
                  channels_needing_rest: engine.channels_needing_rest
                }
              end

              def fatigue_recommendations(**)
                recommendations = engine.delegation_recommendations
                needs_rest      = engine.channels_needing_rest
                log.debug("[cognitive_fatigue] recommendations: delegate=#{recommendations.size} rest=#{needs_rest.size}")
                {
                  delegate:          recommendations,
                  rest:              needs_rest,
                  any_action_needed: recommendations.any? || needs_rest.any?
                }
              end

              def cognitive_quality_report(**)
                report = engine.quality_report
                log.debug("[cognitive_fatigue] quality: channels=#{report.keys.join(',')}")
                { quality: report }
              end

              def update_cognitive_fatigue_model(**)
                depleted = engine.channels_needing_rest
                rested_channels = depleted.map { |ch| engine.rest_channel(channel_name: ch[:name]) }
                log.info("[cognitive_fatigue] model updated: #{depleted.size} depleted channels rested")
                { rested: depleted.size, channels: rested_channels, overall_fatigue: engine.overall_fatigue.round(4) }
              rescue StandardError => e
                log.error("[cognitive_fatigue] update_cognitive_fatigue_model failed: #{e.message}")
                { rested: 0, channels: [], error: e.message }
              end

              def cognitive_fatigue_model_stats(**)
                engine.to_h
              end

              private

              def engine
                @engine ||= Helpers::FatigueEngine.new
              end
            end
          end
        end
      end
    end
  end
end
