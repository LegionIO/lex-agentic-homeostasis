# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Temporal
          module Runners
            module Temporal
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def mark_event(event:, domain: :general, **)
                key = temporal_store.record_event(event, domain: domain)
                count = temporal_store.perception.event_count(event, domain: domain)
                { marked: true, key: key, event: event, domain: domain, total_occurrences: count }
              end

              def elapsed_since(event:, domain: :general, **)
                elapsed = temporal_store.elapsed(event, domain: domain)
                if elapsed
                  { event: event, domain: domain, elapsed_seconds: elapsed, human: humanize_duration(elapsed) }
                else
                  { event: event, domain: domain, elapsed_seconds: nil, reason: :no_record }
                end
              end

              def set_deadline(id:, at:, description: nil, **)
                temporal_store.perception.set_deadline(id, at: at, description: description)
                { set: true, id: id, at: at, description: description }
              end

              def check_deadlines(**)
                {
                  overdue:  temporal_store.perception.overdue_deadlines,
                  upcoming: temporal_store.perception.upcoming_deadlines,
                  urgency:  temporal_store.perception.overall_urgency,
                  total:    temporal_store.perception.deadlines.size
                }
              end

              def update_time_perception(tick_results: {}, **)
                arousal = extract_arousal(tick_results)
                load = extract_cognitive_load(tick_results)
                rate = temporal_store.perception.update_subjective_time(arousal: arousal, cognitive_load: load)
                {
                  subjective_rate: rate,
                  interpretation:  interpret_rate(rate),
                  overall_urgency: temporal_store.perception.overall_urgency,
                  overdue_count:   temporal_store.perception.overdue_deadlines.size
                }
              end

              def predict_event(event:, domain: :general, **)
                prediction = temporal_store.predict_next(event, domain: domain)
                if prediction
                  { prediction: prediction, event: event, domain: domain }
                else
                  { prediction: nil, reason: :insufficient_data }
                end
              end

              def temporal_patterns(**)
                {
                  all:      temporal_store.all_patterns,
                  periodic: temporal_store.periodic_patterns,
                  count:    temporal_store.patterns.size
                }
              end

              def temporal_stats(**)
                temporal_store.temporal_summary
              end

              private

              def extract_arousal(tick_results)
                emotion = tick_results[:emotional_evaluation]
                return 0.5 unless emotion.is_a?(Hash)

                emotion[:arousal] || 0.5
              end

              def extract_cognitive_load(tick_results)
                elapsed = tick_results[:elapsed] || 0
                budget = tick_results[:budget] || 1
                return 0.5 if budget.zero?

                (elapsed.to_f / budget).clamp(0.0, 1.0)
              end

              def humanize_duration(seconds)
                if seconds < 60
                  "#{seconds.round(1)}s"
                elsif seconds < 3600
                  "#{(seconds / 60).round(1)}m"
                elsif seconds < 86_400
                  "#{(seconds / 3600).round(1)}h"
                else
                  "#{(seconds / 86_400).round(1)}d"
                end
              end

              def interpret_rate(rate)
                if rate > 1.5
                  :time_crawling
                elsif rate > 1.1
                  :time_slow
                elsif rate < 0.7
                  :time_flying
                elsif rate < 0.9
                  :time_fast
                else
                  :normal
                end
              end
            end
          end
        end
      end
    end
  end
end
