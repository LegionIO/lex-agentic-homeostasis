# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Hourglass
          module Helpers
            class Hourglass
              attr_reader :id, :top_level, :bottom_level, :neck_width, :state,
                          :created_at, :flipped_at, :domain, :grain_type

              def initialize(domain: nil, grain_type: :attention, top_level: 1.0,
                             neck_width: 0.5, bottom_level: 0.0)
                validate_args!(grain_type, top_level, bottom_level, neck_width)

                @id           = SecureRandom.uuid
                @domain       = domain&.to_s
                @grain_type   = grain_type.to_sym
                @top_level    = top_level.to_f.clamp(0.0, 1.0).round(10)
                @bottom_level = bottom_level.to_f.clamp(0.0, 1.0).round(10)
                @neck_width   = neck_width.to_f.clamp(0.0, 1.0).round(10)
                @created_at   = Time.now.utc
                @flipped_at   = nil
                @state        = derive_state
              end

              # Advance one flow tick — sand moves from top to bottom through the neck
              def flow!(rate = Constants::FLOW_RATE)
                return self if @state == :paused
                return self if expired?

                effective_rate = (rate.to_f * @neck_width).clamp(0.0, 1.0).round(10)
                transferred    = [@top_level, effective_rate].min.round(10)

                @top_level    = (@top_level - transferred).clamp(0.0, 1.0).round(10)
                @bottom_level = (@bottom_level + transferred).clamp(0.0, 1.0).round(10)

                @state = derive_state
                self
              end

              # Flip the hourglass — top and bottom swap, state resets to flowing
              def flip!
                @top_level, @bottom_level = @bottom_level, @top_level
                @top_level    = @top_level.round(10)
                @bottom_level = @bottom_level.round(10)
                @flipped_at   = Time.now.utc
                @state        = derive_state
                self
              end

              # Pause flow — grains stop moving through the neck
              def pause!
                @state = :paused
                self
              end

              # Resume flow — grains move again, state re-derived from levels
              def resume!
                @state = derive_state
                self
              end

              # Top chamber is empty — no more cognitive resource remaining
              def expired?
                @top_level <= 0.0
              end

              # Just flipped within the last 30 seconds
              def fresh?
                return false unless @flipped_at

                (Time.now.utc - @flipped_at) < 30.0
              end

              # Urgency label based on how empty the top chamber is
              def urgency_label
                urgency = 1.0 - @top_level
                Constants.label_for(:URGENCY_LABELS, urgency)
              end

              # Fullness label based on the top chamber level
              def fullness_label
                Constants.label_for(:FULLNESS_LABELS, @top_level)
              end

              def to_h
                {
                  id:             @id,
                  domain:         @domain,
                  grain_type:     @grain_type,
                  top_level:      @top_level,
                  bottom_level:   @bottom_level,
                  neck_width:     @neck_width,
                  state:          @state,
                  expired:        expired?,
                  fresh:          fresh?,
                  urgency_label:  urgency_label,
                  fullness_label: fullness_label,
                  created_at:     @created_at,
                  flipped_at:     @flipped_at
                }
              end

              private

              def validate_args!(grain_type, top_level, bottom_level, neck_width)
                raise ArgumentError, "unknown grain_type: #{grain_type}" unless Constants::GRAIN_TYPES.include?(grain_type.to_sym)
                raise ArgumentError, 'top_level must be between 0.0 and 1.0' unless (0.0..1.0).cover?(top_level.to_f)
                raise ArgumentError, 'bottom_level must be between 0.0 and 1.0' unless (0.0..1.0).cover?(bottom_level.to_f)
                raise ArgumentError, 'neck_width must be between 0.0 and 1.0' unless (0.0..1.0).cover?(neck_width.to_f)
              end

              def derive_state
                return :empty  if @top_level <= 0.0
                return :full   if @bottom_level <= 0.0 && @top_level >= 1.0

                :flowing
              end
            end
          end
        end
      end
    end
  end
end
