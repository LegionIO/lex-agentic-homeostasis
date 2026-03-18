# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FatigueModel
          module Helpers
            class FatigueEngine
              include Constants

              def initialize
                @channels = {}
                CHANNELS.each { |name| create_channel(name: name) }
              end

              def create_channel(name:)
                @channels[name] = Channel.new(name: name)
              end

              def process_task(channel_name:)
                channel = fetch_channel(channel_name)
                channel.deplete!
                channel.to_h
              end

              def rest_channel(channel_name:)
                channel = fetch_channel(channel_name)
                channel.recover!
                channel.to_h
              end

              def rest_all
                @channels.each_value(&:recover!)
                to_h
              end

              def channel_status(channel_name:)
                fetch_channel(channel_name).to_h
              end

              def overall_fatigue
                return 0.0 if @channels.empty?

                total = @channels.values.sum(&:energy)
                total / @channels.size
              end

              def most_fatigued_channel
                return nil if @channels.empty?

                @channels.values.min_by(&:energy).to_h
              end

              def channels_needing_rest
                @channels.values.select(&:needs_rest?).map(&:to_h)
              end

              def delegation_recommendations
                @channels.values.select(&:needs_delegation?).map(&:to_h)
              end

              def quality_report
                @channels.transform_values(&:quality_modifier)
              end

              def to_h
                {
                  channels:        @channels.transform_values(&:to_h),
                  overall_fatigue: overall_fatigue.round(4),
                  channel_count:   @channels.size
                }
              end

              private

              def fetch_channel(name)
                @channels.fetch(name) { raise ArgumentError, "Unknown channel: #{name.inspect}" }
              end
            end
          end
        end
      end
    end
  end
end
