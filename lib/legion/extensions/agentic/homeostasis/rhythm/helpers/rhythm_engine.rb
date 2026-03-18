# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Rhythm
          module Helpers
            class RhythmEngine
              include Constants

              def initialize
                @rhythms  = {}
                @counter  = 0
                @history  = []
              end

              def add_rhythm(name:, rhythm_type:, dimension:, period: nil, amplitude: 0.5, phase_offset: 0.0)
                return nil unless RHYTHM_TYPES.include?(rhythm_type.to_sym)
                return nil unless COGNITIVE_DIMENSIONS.include?(dimension.to_sym)
                return nil if @rhythms.size >= MAX_RHYTHMS

                resolved_period = resolve_period(rhythm_type, period)
                return nil if resolved_period.nil?

                @counter += 1
                id = :"rhythm_#{@counter}"
                rhythm = Rhythm.new(
                  id:           id,
                  name:         name,
                  rhythm_type:  rhythm_type,
                  dimension:    dimension,
                  period:       resolved_period,
                  amplitude:    amplitude,
                  phase_offset: phase_offset
                )
                @rhythms[id] = rhythm
                rhythm
              end

              def remove_rhythm(rhythm_id:)
                removed = @rhythms.delete(rhythm_id)
                removed ? { success: true, rhythm_id: rhythm_id } : { success: false, reason: :not_found }
              end

              def dimension_value(dimension:)
                matching = @rhythms.values.select { |r| r.dimension == dimension }
                return 0.0 if matching.empty?

                matching.sum(&:current_value) / matching.size
              end

              def current_state
                COGNITIVE_DIMENSIONS.to_h do |dim|
                  [dim, dimension_value(dimension: dim).round(4)]
                end
              end

              def optimal_for(dimension:)
                matching = @rhythms.values.select { |r| r.dimension == dimension }
                return false if matching.empty?

                matching.any?(&:peak?)
              end

              def best_time_for(dimension:, within: 3600)
                matching = @rhythms.values.select { |r| r.dimension == dimension }
                return nil if matching.empty?

                now = Time.now.utc.to_f
                step = 60
                steps = within / step

                best_time  = nil
                best_value = -1.0

                (0..steps).each do |i|
                  t = now + (i * step)
                  value = matching.sum { |r| r.value_at(t) } / matching.size
                  if value > best_value
                    best_value = value
                    best_time  = t
                  end
                end

                best_time ? Time.at(best_time).utc : nil
              end

              def synchronize(rhythm_ids:)
                rhythms = rhythm_ids.map { |id| @rhythms[id] }.compact
                return { success: false, reason: :not_found } if rhythms.empty?

                reference_phase = rhythms.first.current_phase
                rhythms.each do |r|
                  current = r.current_phase
                  offset_adjustment = (reference_phase - current) * r.period
                  instance_variable_set_phase_offset(r, r.phase_offset + offset_adjustment)
                end

                { success: true, synchronized: rhythms.map(&:id) }
              end

              def cognitive_profile
                current = current_state
                current.each_with_object({}) do |(dim, value), hash|
                  phase_label = dominant_phase_label(dim)
                  amplitude_label = dominant_amplitude_label(dim)
                  hash[dim] = {
                    value:           value,
                    phase_label:     phase_label,
                    amplitude_label: amplitude_label,
                    optimal:         optimal_for(dimension: dim)
                  }
                end
              end

              def peak_dimensions
                COGNITIVE_DIMENSIONS.select { |dim| optimal_for(dimension: dim) }
              end

              def trough_dimensions
                COGNITIVE_DIMENSIONS.select do |dim|
                  matching = @rhythms.values.select { |r| r.dimension == dim }
                  matching.any?(&:trough?)
                end
              end

              def to_h
                {
                  rhythm_count:  @rhythms.size,
                  rhythms:       @rhythms.values.map(&:to_h),
                  current_state: current_state
                }
              end

              private

              def resolve_period(rhythm_type, period)
                case rhythm_type
                when :ultradian then ULTRADIAN_PERIOD
                when :circadian  then CIRCADIAN_PERIOD
                when :custom     then period
                end
              end

              def dominant_phase_label(dimension)
                matching = @rhythms.values.select { |r| r.dimension == dimension }
                return :none if matching.empty?

                matching.max_by(&:current_value)&.phase_label || :none
              end

              def dominant_amplitude_label(dimension)
                matching = @rhythms.values.select { |r| r.dimension == dimension }
                return :none if matching.empty?

                matching.max_by(&:amplitude)&.amplitude_label || :none
              end

              def instance_variable_set_phase_offset(rhythm, new_offset)
                rhythm.instance_variable_set(:@phase_offset, new_offset.to_f)
              end
            end
          end
        end
      end
    end
  end
end
