# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Temporal
          module Helpers
            class TemporalStore
              attr_reader :perception, :patterns

              def initialize
                @perception = TimePerception.new
                @patterns = {}
              end

              def record_event(event, domain: :general)
                key = @perception.mark_event(event, domain: domain)
                update_pattern(domain, event)
                key
              end

              def elapsed(event, domain: :general)
                @perception.elapsed_since(event, domain: domain)
              end

              def predict_next(event, domain: :general)
                pattern_key = "#{domain}:#{event}"
                pattern = @patterns[pattern_key]
                return nil unless pattern

                pattern.predict_next
              end

              def record_prediction_outcome(event, actual_time:, domain: :general)
                pattern_key = "#{domain}:#{event}"
                pattern = @patterns[pattern_key]
                pattern&.record_actual(actual_time)
              end

              def detect_patterns_for(event, domain: :general)
                pattern_key = "#{domain}:#{event}"
                @patterns[pattern_key]&.to_h
              end

              def all_patterns
                @patterns.values.map(&:to_h)
              end

              def periodic_patterns
                @patterns.values.select(&:periodic?).map(&:to_h)
              end

              def temporal_summary
                {
                  perception:        @perception.to_h,
                  pattern_count:     @patterns.size,
                  periodic_count:    @patterns.values.count(&:periodic?),
                  bursty_count:      @patterns.values.count(&:bursty?),
                  overall_urgency:   @perception.overall_urgency,
                  overdue_deadlines: @perception.overdue_deadlines.size
                }
              end

              private

              def update_pattern(domain, event)
                pattern_key = "#{domain}:#{event}"
                event_key = "#{domain}:#{event}"
                timestamps = @perception.events[event_key]
                return unless timestamps && timestamps.size >= 2

                @patterns[pattern_key] ||= TemporalPattern.new(domain: domain, event: event)
                @patterns[pattern_key].add_observation(timestamps)
                evict_patterns_if_needed
              end

              def evict_patterns_if_needed
                return unless @patterns.size > Constants::MAX_PATTERNS

                weakest = @patterns.min_by { |_k, p| p.observation_count }
                @patterns.delete(weakest.first) if weakest
              end
            end
          end
        end
      end
    end
  end
end
