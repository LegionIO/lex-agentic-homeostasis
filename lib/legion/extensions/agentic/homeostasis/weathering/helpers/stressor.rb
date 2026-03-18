# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weathering
          module Helpers
            class Stressor
              include Constants

              attr_reader :id, :description, :stressor_type, :intensity, :duration, :domain, :recorded_at

              def initialize(description:, stressor_type:, intensity:, duration:, domain: nil)
                @id           = SecureRandom.uuid
                @description  = description
                @stressor_type = validate_type(stressor_type)
                @intensity    = intensity.clamp(0.0, 1.0)
                @duration     = [duration.to_f, 0.0].max
                @domain       = domain
                @recorded_at  = Time.now.utc
              end

              def cumulative_impact
                (intensity * (duration / 3600.0)).clamp(0.0, 1.0).round(10)
              end

              def manageable?
                intensity <= Constants::TEMPERING_THRESHOLD
              end

              def overwhelming?
                intensity >= 0.8
              end

              def to_h
                {
                  id:                id,
                  description:       description,
                  stressor_type:     stressor_type,
                  intensity:         intensity,
                  duration:          duration,
                  domain:            domain,
                  cumulative_impact: cumulative_impact,
                  manageable:        manageable?,
                  overwhelming:      overwhelming?,
                  recorded_at:       recorded_at.iso8601
                }
              end

              private

              def validate_type(type)
                sym = type.to_sym
                Constants::STRESSOR_TYPES.include?(sym) ? sym : :cognitive_overload
              end
            end
          end
        end
      end
    end
  end
end
