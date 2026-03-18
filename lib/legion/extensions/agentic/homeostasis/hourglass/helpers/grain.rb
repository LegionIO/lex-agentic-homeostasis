# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Hourglass
          module Helpers
            class Grain
              attr_reader :id, :grain_type, :domain, :content, :weight, :created_at

              def initialize(grain_type:, domain: nil, content: nil, weight: 1.0)
                raise ArgumentError, "unknown grain_type: #{grain_type}" unless Constants::GRAIN_TYPES.include?(grain_type.to_sym)
                raise ArgumentError, 'weight must be between 0.0 and 1.0' unless (0.0..1.0).cover?(weight.to_f)

                @id         = SecureRandom.uuid
                @grain_type = grain_type.to_sym
                @domain     = domain&.to_s
                @content    = content
                @weight     = weight.to_f.clamp(0.0, 1.0).round(10)
                @created_at = Time.now.utc
              end

              # Erode the grain — reduce weight by rate, floors at 0.0
              def erode!(rate = 0.01)
                @weight = (@weight - rate.to_f.clamp(0.0, 1.0)).clamp(0.0, 1.0).round(10)
                self
              end

              # Solidify the grain — increase weight by rate, caps at 1.0
              def solidify!(rate = 0.01)
                @weight = (@weight + rate.to_f.clamp(0.0, 1.0)).clamp(0.0, 1.0).round(10)
                self
              end

              # A grain is dust when its weight is below 0.05 — nearly weightless
              def dust?
                @weight < 0.05
              end

              # A grain is heavy when its weight is above 0.75 — substantial cognitive unit
              def heavy?
                @weight > 0.75
              end

              def to_h
                {
                  id:         @id,
                  grain_type: @grain_type,
                  domain:     @domain,
                  content:    @content,
                  weight:     @weight,
                  created_at: @created_at,
                  dust:       dust?,
                  heavy:      heavy?
                }
              end
            end
          end
        end
      end
    end
  end
end
