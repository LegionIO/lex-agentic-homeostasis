# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tempo
          module Helpers
            class TempoEngine
              attr_reader :records, :domain_baselines

              def initialize
                @records          = {}
                @domain_baselines = {}
              end

              def set_baseline(domain:, tempo:)
                @domain_baselines[domain] = tempo.clamp(0.0, 1.0)
              end

              def record_tempo(domain:, current_tempo:, task_requirement:)
                entry = TempoRecord.new(
                  domain:                 domain,
                  baseline_tempo:         @domain_baselines.fetch(domain, Constants::DEFAULT_TEMPO),
                  current_tempo:          current_tempo,
                  task_tempo_requirement: task_requirement
                )

                @records[domain] ||= []
                @records[domain] << entry
                trim_domain(domain)
                entry
              end

              def adapt_tempo(domain:, target:)
                latest = latest_record(domain)
                return nil unless latest

                latest.adapt_to!(target: target)
                latest
              end

              def average_mismatch
                all = @records.values.flatten
                return 0.0 if all.empty?

                all.sum(&:mismatch) / all.size.to_f
              end

              def domains_in_sync
                @records.keys.select do |domain|
                  latest = latest_record(domain)
                  next false unless latest

                  latest.mismatch <= 0.1
                end
              end

              def domains_mismatched
                @records.keys.reject do |domain|
                  latest = latest_record(domain)
                  next true unless latest

                  latest.mismatch <= 0.1
                end
              end

              def tempo_report
                {
                  domains:          @records.keys,
                  average_mismatch: average_mismatch.round(10),
                  in_sync:          domains_in_sync,
                  mismatched:       domains_mismatched,
                  total_records:    @records.values.sum(&:size)
                }
              end

              def to_h
                {
                  domain_baselines: @domain_baselines,
                  records:          @records.transform_values { |recs| recs.map(&:to_h) }
                }
              end

              private

              def latest_record(domain)
                @records[domain]&.last
              end

              def trim_domain(domain)
                list = @records[domain]
                return unless list && list.size > Constants::MAX_TEMPO_RECORDS

                list.shift while list.size > Constants::MAX_TEMPO_RECORDS
              end
            end
          end
        end
      end
    end
  end
end
