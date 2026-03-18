# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Rhythm
          module Helpers
            class Rhythm
              include Constants

              attr_reader :id, :name, :rhythm_type, :dimension, :period,
                          :amplitude, :phase_offset, :created_at

              def initialize(id:, name:, rhythm_type:, dimension:, period:,
                             amplitude: 0.5, phase_offset: 0.0)
                @id           = id
                @name         = name
                @rhythm_type  = rhythm_type
                @dimension    = dimension
                @period       = period
                @amplitude    = amplitude.to_f.clamp(MIN_AMPLITUDE, MAX_AMPLITUDE)
                @phase_offset = phase_offset.to_f
                @created_at   = Time.now.utc
              end

              def value_at(time)
                elapsed = time.to_f - @created_at.to_f + @phase_offset
                @amplitude * (0.5 + (0.5 * Math.sin(2 * Math::PI * (elapsed / @period))))
              end

              def current_value
                value_at(Time.now.utc)
              end

              def phase_at(time)
                elapsed = time.to_f - @created_at.to_f + @phase_offset
                (elapsed % @period) / @period
              end

              def current_phase
                phase_at(Time.now.utc)
              end

              def phase_label
                phase = current_phase
                PHASE_LABELS.each { |range, label| return label if range.cover?(phase) }
                :trough
              end

              def amplitude_label
                AMPLITUDE_LABELS.each { |range, label| return label if range.cover?(@amplitude) }
                :low
              end

              def peak?
                phase_label == :peak
              end

              def trough?
                phase_label == :trough
              end

              def rising?
                phase_label == :rising
              end

              def falling?
                phase_label == :falling
              end

              def to_h
                {
                  id:              @id,
                  name:            @name,
                  rhythm_type:     @rhythm_type,
                  dimension:       @dimension,
                  period:          @period,
                  amplitude:       @amplitude,
                  phase_offset:    @phase_offset,
                  current_value:   current_value.round(4),
                  current_phase:   current_phase.round(4),
                  phase_label:     phase_label,
                  amplitude_label: amplitude_label
                }
              end
            end
          end
        end
      end
    end
  end
end
