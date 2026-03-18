# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Rhythm
          module Runners
            module CognitiveRhythm
              include Helpers::Constants
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def add_cognitive_rhythm(name:, rhythm_type:, dimension:, period: nil,
                                       amplitude: 0.5, phase_offset: 0.0, **)
                rhythm = engine.add_rhythm(
                  name:         name,
                  rhythm_type:  rhythm_type,
                  dimension:    dimension,
                  period:       period,
                  amplitude:    amplitude,
                  phase_offset: phase_offset
                )
                return { success: false, reason: :limit_reached_or_invalid } unless rhythm

                { success: true, rhythm_id: rhythm.id, name: rhythm.name, dimension: rhythm.dimension }
              end

              def remove_cognitive_rhythm(rhythm_id:, **)
                result = engine.remove_rhythm(rhythm_id: rhythm_id)
                result[:success] ? result : { success: false, reason: result[:reason] }
              end

              def current_rhythm_state(**)
                { success: true, state: engine.current_state }
              end

              def dimension_rhythm_value(dimension:, **)
                value = engine.dimension_value(dimension: dimension)
                { success: true, dimension: dimension, value: value.round(4) }
              end

              def optimal_for_task(dimension:, **)
                { success: true, dimension: dimension, optimal: engine.optimal_for(dimension: dimension) }
              end

              def best_time_for_task(dimension:, within: 3600, **)
                time = engine.best_time_for(dimension: dimension, within: within)
                return { success: false, reason: :no_rhythms_for_dimension } unless time

                { success: true, dimension: dimension, best_time: time.iso8601, within_seconds: within }
              end

              def cognitive_rhythm_profile(**)
                { success: true, profile: engine.cognitive_profile }
              end

              def peak_cognitive_dimensions(**)
                dims = engine.peak_dimensions
                { success: true, dimensions: dims, count: dims.size }
              end

              def trough_cognitive_dimensions(**)
                dims = engine.trough_dimensions
                { success: true, dimensions: dims, count: dims.size }
              end

              def cognitive_rhythm_stats(**)
                { success: true }.merge(engine.to_h)
              end

              private

              def engine
                @engine ||= Helpers::RhythmEngine.new
              end
            end
          end
        end
      end
    end
  end
end
