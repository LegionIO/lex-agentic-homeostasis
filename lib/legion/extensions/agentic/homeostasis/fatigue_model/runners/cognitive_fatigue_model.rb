# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FatigueModel
          module Runners
            module CognitiveFatigueModel
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex)

              def process_cognitive_task(channel_name:, **)
                result = engine.process_task(channel_name: channel_name)
                Legion::Logging.debug "[cognitive_fatigue] task: channel=#{channel_name} energy=#{result[:energy]} label=#{result[:label]}"
                { channel: result, overall_fatigue: engine.overall_fatigue.round(4) }
              end

              def rest_cognitive_channel(channel_name:, **)
                result = engine.rest_channel(channel_name: channel_name)
                Legion::Logging.debug "[cognitive_fatigue] rest channel: channel=#{channel_name} energy=#{result[:energy]}"
                { channel: result }
              end

              def rest_all_channels(**)
                result = engine.rest_all
                Legion::Logging.debug "[cognitive_fatigue] rest all: overall=#{result[:overall_fatigue]}"
                result
              end

              def channel_fatigue_status(channel_name:, **)
                result = engine.channel_status(channel_name: channel_name)
                Legion::Logging.debug "[cognitive_fatigue] status: channel=#{channel_name} energy=#{result[:energy]}"
                result
              end

              def overall_fatigue_report(**)
                fatigue = engine.overall_fatigue
                most_fatigued = engine.most_fatigued_channel
                Legion::Logging.debug "[cognitive_fatigue] overall: fatigue=#{fatigue.round(4)}"
                {
                  overall_fatigue:       fatigue.round(4),
                  most_fatigued:         most_fatigued,
                  channels_needing_rest: engine.channels_needing_rest
                }
              end

              def fatigue_recommendations(**)
                recommendations = engine.delegation_recommendations
                needs_rest      = engine.channels_needing_rest
                Legion::Logging.debug "[cognitive_fatigue] recommendations: delegate=#{recommendations.size} rest=#{needs_rest.size}"
                {
                  delegate:          recommendations,
                  rest:              needs_rest,
                  any_action_needed: recommendations.any? || needs_rest.any?
                }
              end

              def cognitive_quality_report(**)
                report = engine.quality_report
                Legion::Logging.debug "[cognitive_fatigue] quality: channels=#{report.keys.join(',')}"
                { quality: report }
              end

              def update_cognitive_fatigue_model(**)
                result = engine.rest_all
                Legion::Logging.info '[cognitive_fatigue] model updated: all channels rested'
                result
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
