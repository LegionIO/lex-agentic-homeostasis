# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Temporal
          module Helpers
            class TemporalPattern
              attr_reader :domain, :event, :pattern_type, :mean_interval,
                          :observation_count, :last_predicted, :accuracy_count, :total_predictions

              def initialize(domain:, event:)
                @domain = domain
                @event = event
                @intervals = []
                @pattern_type = :random
                @mean_interval = nil
                @observation_count = 0
                @last_predicted = nil
                @accuracy_count = 0
                @total_predictions = 0
              end

              def add_observation(timestamps)
                return if timestamps.size < 2

                @intervals = compute_intervals(timestamps)
                @observation_count = timestamps.size
                @mean_interval = @intervals.sum / @intervals.size.to_f
                @pattern_type = classify_pattern
              end

              def predict_next(from: Time.now.utc)
                return nil unless @mean_interval && @observation_count >= Constants::MIN_PATTERN_OBSERVATIONS

                predicted = from + @mean_interval
                @last_predicted = predicted
                @total_predictions += 1
                { predicted_at: predicted, confidence: prediction_confidence, pattern: @pattern_type }
              end

              def record_actual(actual_time)
                return unless @last_predicted

                error = (actual_time - @last_predicted).abs
                tolerance = (@mean_interval || 60) * 0.3
                @accuracy_count += 1 if error <= tolerance
              end

              def prediction_accuracy
                return 0.0 if @total_predictions.zero?

                @accuracy_count.to_f / @total_predictions
              end

              def periodic?
                @pattern_type == :periodic
              end

              def bursty?
                @pattern_type == :bursty
              end

              def to_h
                {
                  domain:            @domain,
                  event:             @event,
                  pattern_type:      @pattern_type,
                  mean_interval:     @mean_interval,
                  observation_count: @observation_count,
                  accuracy:          prediction_accuracy
                }
              end

              private

              def compute_intervals(timestamps)
                sorted = timestamps.sort
                sorted.each_cons(2).map { |a, b| b - a }
              end

              def classify_pattern
                return :random if @intervals.size < Constants::MIN_PATTERN_OBSERVATIONS

                cv = coefficient_of_variation
                if cv < Constants::PERIODIC_CV_THRESHOLD
                  :periodic
                elsif bursts?
                  :bursty
                else
                  :random
                end
              end

              def coefficient_of_variation
                return Float::INFINITY if @intervals.empty? || @mean_interval.nil? || @mean_interval.zero?

                std_dev = Math.sqrt(@intervals.sum { |i| (i - @mean_interval)**2 } / @intervals.size.to_f)
                std_dev / @mean_interval
              end

              def bursts?
                return false unless @mean_interval

                burst_threshold = @mean_interval * Constants::BURST_MULTIPLIER
                burst_count = @intervals.count { |i| i < burst_threshold }
                burst_count > @intervals.size * 0.3
              end

              def prediction_confidence
                base = case @pattern_type
                       when :periodic then 0.8
                       when :bursty then 0.4
                       else 0.2
                       end
                base * [1.0, @observation_count / 10.0].min
              end
            end
          end
        end
      end
    end
  end
end
