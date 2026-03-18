# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Weather
          module Helpers
            class Storm
              attr_reader :id, :condition, :front_ids, :created_at, :insight_log
              attr_accessor :intensity, :coverage

              def initialize(condition:, front_ids: [], intensity: 0.5, coverage: 0.5)
                raise ArgumentError, "unknown condition: #{condition}" unless Constants::CONDITION_TYPES.include?(condition.to_sym)

                @id          = SecureRandom.uuid
                @condition   = condition.to_sym
                @front_ids   = Array(front_ids).dup
                @intensity   = intensity.clamp(0.0, 1.0)
                @coverage    = coverage.clamp(0.0, 1.0)
                @created_at  = Time.now.utc
                @insight_log = []
              end

              # Intensify: storm grows stronger
              def intensify!(rate = Constants::PRESSURE_CHANGE_RATE)
                @intensity = (@intensity + rate.clamp(0.0, 1.0)).clamp(0.0, 1.0)
                @coverage  = (@coverage  + (rate * 0.5).clamp(0.0, 1.0)).clamp(0.0, 1.0)
              end

              # Dissipate: storm weakens and clears
              def dissipate!(rate = Constants::DISSIPATION_RATE)
                @intensity = (@intensity - rate.clamp(0.0, 1.0)).clamp(0.0, 1.0)
                @coverage  = (@coverage  - (rate * 0.5).clamp(0.0, 1.0)).clamp(0.0, 1.0)
              end

              # A lightning strike of sudden insight — random intensity, logged for audit
              def lightning_strike!(domain: nil)
                insight_id = SecureRandom.uuid
                insight_intensity = rand.round(10)
                entry = {
                  id:        insight_id,
                  domain:    domain,
                  intensity: insight_intensity,
                  struck_at: Time.now.utc.iso8601
                }
                @insight_log << entry
                entry
              end

              def raging?
                @intensity >= 0.75
              end

              def clearing?
                @intensity <= 0.25
              end

              def clarity_label
                # Clarity is inverse of intensity: high intensity = low clarity
                Constants.label_for(Constants::CLARITY_LABELS, 1.0 - @intensity)
              end

              def to_h
                {
                  id:            @id,
                  condition:     @condition,
                  front_ids:     @front_ids,
                  intensity:     @intensity.round(10),
                  coverage:      @coverage.round(10),
                  raging:        raging?,
                  clearing:      clearing?,
                  clarity:       clarity_label,
                  insight_count: @insight_log.size,
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
