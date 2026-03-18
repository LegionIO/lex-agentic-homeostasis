# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Hourglass
          module Helpers
            class HourglassEngine
              attr_reader :hourglasses, :grains

              def initialize
                @hourglasses = {}
                @grains      = {}
              end

              # Create a grain and register it; raises ArgumentError if MAX_GRAINS reached
              def create_grain(grain_type:, domain: nil, content: nil, weight: 1.0)
                raise ArgumentError, "MAX_GRAINS (#{Constants::MAX_GRAINS}) reached" if @grains.size >= Constants::MAX_GRAINS

                grain = Grain.new(
                  grain_type: grain_type,
                  domain:     domain,
                  content:    content,
                  weight:     weight
                )
                @grains[grain.id] = grain
                grain
              end

              # Create an hourglass and register it; raises ArgumentError if MAX_HOURGLASSES reached
              def create_hourglass(domain: nil, grain_type: :attention, top_level: 1.0,
                                   neck_width: 0.5, bottom_level: 0.0)
                raise ArgumentError, "MAX_HOURGLASSES (#{Constants::MAX_HOURGLASSES}) reached" if @hourglasses.size >= Constants::MAX_HOURGLASSES

                hourglass = Hourglass.new(
                  domain:       domain,
                  grain_type:   grain_type,
                  top_level:    top_level,
                  neck_width:   neck_width,
                  bottom_level: bottom_level
                )
                @hourglasses[hourglass.id] = hourglass
                hourglass
              end

              # Advance all non-expired hourglasses by one flow tick
              def flow_tick(rate = Constants::FLOW_RATE)
                ticked    = 0
                expired   = 0
                blocked   = 0

                @hourglasses.each_value do |h|
                  if h.state == :paused
                    blocked += 1
                    next
                  end

                  if h.expired?
                    expired += 1
                    next
                  end

                  if rand < Constants::BLOCKAGE_CHANCE
                    h.pause!
                    blocked += 1
                  else
                    h.flow!(rate)
                    ticked += 1
                  end
                end

                { ticked: ticked, expired: expired, blocked: blocked, total: @hourglasses.size }
              end

              # Flip a specific hourglass by id; raises ArgumentError if not found
              def flip(hourglass_id)
                h = @hourglasses.fetch(hourglass_id) do
                  raise ArgumentError, "hourglass not found: #{hourglass_id}"
                end
                h.flip!
                h
              end

              # Return the hourglass closest to expired (lowest top_level, not already expired)
              def most_urgent
                candidates = @hourglasses.values.reject(&:expired?).reject { |h| h.state == :paused }
                candidates.min_by(&:top_level)
              end

              # Return the hourglass with the most sand in the bottom (most depleted from top)
              def most_depleted
                @hourglasses.values.max_by(&:bottom_level)
              end

              # Return a summary report of all hourglasses grouped by state
              def flow_report
                grouped = @hourglasses.values.group_by(&:state)

                {
                  total:         @hourglasses.size,
                  grain_count:   @grains.size,
                  flowing:       grouped.fetch(:flowing,  []).size,
                  blocked:       grouped.fetch(:blocked,  []).size,
                  empty:         grouped.fetch(:empty,    []).size,
                  full:          grouped.fetch(:full,     []).size,
                  paused:        grouped.fetch(:paused,   []).size,
                  most_urgent:   most_urgent&.to_h,
                  most_depleted: most_depleted&.to_h,
                  hourglasses:   @hourglasses.values.map(&:to_h)
                }
              end
            end
          end
        end
      end
    end
  end
end
