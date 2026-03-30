# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Temporal
          module Helpers
            class TimePerception
              attr_reader :events, :deadlines, :subjective_rate

              def initialize
                @events = {}
                @deadlines = {}
                @subjective_rate = 1.0
                @tick_count = 0
              end

              def mark_event(event, domain: :general)
                key = "#{domain}:#{event}"
                @events[key] ||= []
                @events[key] << Time.now.utc
                trim_events(key)
                key
              end

              def elapsed_since(event, domain: :general)
                key = "#{domain}:#{event}"
                timestamps = @events[key]
                return nil unless timestamps&.any?

                Time.now.utc - timestamps.last
              end

              def time_since_first(event, domain: :general)
                key = "#{domain}:#{event}"
                timestamps = @events[key]
                return nil unless timestamps&.any?

                Time.now.utc - timestamps.first
              end

              def event_count(event, domain: :general)
                key = "#{domain}:#{event}"
                @events.fetch(key, []).size
              end

              def set_deadline(id, at:, description: nil)
                @deadlines[id] = { at: at, created: Time.now.utc, description: description }
                evict_deadlines_if_needed
                id
              end

              def remove_deadline(id)
                @deadlines.delete(id)
              end

              def deadline_urgency(id)
                dl = @deadlines[id]
                return nil unless dl

                remaining = dl[:at] - Time.now.utc
                return :overdue if remaining <= 0

                total = dl[:at] - dl[:created]
                return :critical if total <= 0

                fraction = remaining / total
                classify_deadline_urgency(fraction)
              end

              def overdue_deadlines
                now = Time.now.utc
                @deadlines.select { |_id, dl| dl[:at] <= now }
                          .map { |id, dl| { id: id, overdue_by: now - dl[:at], description: dl[:description] } }
              end

              def upcoming_deadlines(within: 3600)
                now = Time.now.utc
                cutoff = now + within
                @deadlines.select { |_id, dl| dl[:at] > now && dl[:at] <= cutoff }
                          .map { |id, dl| { id: id, remaining: dl[:at] - now, description: dl[:description] } }
                          .sort_by { |d| d[:remaining] }
              end

              def update_subjective_time(arousal: 0.5, cognitive_load: 0.5, **)
                @tick_count += 1
                raw_dilation = compute_dilation(arousal, cognitive_load)
                @subjective_rate = ema(@subjective_rate, raw_dilation, Constants::SUBJECTIVE_ALPHA)
                @subjective_rate
              end

              def subjective_elapsed(real_seconds)
                real_seconds * @subjective_rate
              end

              def overall_urgency
                urgencies = @deadlines.keys.filter_map { |id| deadline_urgency(id) }
                return :none if urgencies.empty?

                priority = Constants::URGENCY_LEVELS
                urgencies.min_by { |u| u == :overdue ? -1 : priority.index(u) || 99 }
              end

              def to_h
                {
                  event_domains:    @events.size,
                  active_deadlines: @deadlines.size,
                  overdue_count:    overdue_deadlines.size,
                  subjective_rate:  @subjective_rate,
                  overall_urgency:  overall_urgency,
                  tick_count:       @tick_count
                }
              end

              private

              def trim_events(key)
                return unless @events[key].size > Constants::MAX_EVENTS_PER_DOMAIN

                @events[key] = @events[key].last(Constants::MAX_EVENTS_PER_DOMAIN)
              end

              def evict_deadlines_if_needed
                return unless @deadlines.size > Constants::MAX_DEADLINES

                oldest_key = @deadlines.min_by { |_id, dl| dl[:created] }.first
                @deadlines.delete(oldest_key)
              end

              def classify_deadline_urgency(fraction)
                Constants::DEADLINE_URGENCY.each do |level, threshold|
                  return level if fraction <= threshold
                end
                :none
              end

              def compute_dilation(arousal, cognitive_load)
                raw = 1.0 + ((arousal - 0.5) * 1.0) + ((cognitive_load - 0.5) * 0.5)
                raw.clamp(Constants::DILATION_RANGE[:min], Constants::DILATION_RANGE[:max])
              end

              def ema(current, observed, alpha)
                (current * (1.0 - alpha)) + (observed * alpha)
              end
            end
          end
        end
      end
    end
  end
end
