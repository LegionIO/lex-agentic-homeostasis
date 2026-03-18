# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weather
          module Helpers
            class Front
              attr_reader :id, :front_type, :domain, :created_at
              attr_accessor :pressure, :temperature, :humidity

              def initialize(front_type:, domain:, pressure: 0.5, temperature: 0.5, humidity: 0.5)
                raise ArgumentError, "unknown front_type: #{front_type}" unless Constants::FRONT_TYPES.include?(front_type.to_sym)

                @id          = SecureRandom.uuid
                @front_type  = front_type.to_sym
                @domain      = domain.to_s
                @pressure    = pressure.clamp(0.0, 1.0)
                @temperature = temperature.clamp(0.0, 1.0)
                @humidity    = humidity.clamp(0.0, 1.0)
                @created_at  = Time.now.utc
              end

              # Advance: pressure rises, front strengthens
              def advance!(rate = Constants::PRESSURE_CHANGE_RATE)
                @pressure = (@pressure + rate.clamp(0.0, 1.0)).clamp(0.0, 1.0)
              end

              # Retreat: pressure falls, front weakens
              def retreat!(rate = Constants::PRESSURE_CHANGE_RATE)
                @pressure = (@pressure - rate.clamp(0.0, 1.0)).clamp(0.0, 1.0)
              end

              def high_pressure?
                @pressure >= 0.65
              end

              def low_pressure?
                @pressure <= 0.35
              end

              def severity_label
                Constants.label_for(Constants::SEVERITY_LABELS, @pressure)
              end

              def to_h
                {
                  id:            @id,
                  front_type:    @front_type,
                  domain:        @domain,
                  pressure:      @pressure.round(10),
                  temperature:   @temperature.round(10),
                  humidity:      @humidity.round(10),
                  high_pressure: high_pressure?,
                  low_pressure:  low_pressure?,
                  severity:      severity_label,
                  created_at:    @created_at.iso8601
                }
              end
            end
          end
        end
      end
    end
  end
end
