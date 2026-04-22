# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tempo
          module Runners
            module Tempo
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def set_tempo_baseline(domain:, tempo:, **)
                tempo_engine.set_baseline(domain: domain, tempo: tempo)
                log.debug("[cognitive_tempo] baseline set: domain=#{domain} tempo=#{tempo.round(2)}")
                { domain: domain, baseline: tempo }
              end

              def record_tempo(domain:, current_tempo:, task_requirement:, **)
                record = tempo_engine.record_tempo(
                  domain:           domain,
                  current_tempo:    current_tempo,
                  task_requirement: task_requirement
                )
                log.debug("[cognitive_tempo] recorded: domain=#{domain} " \
                          "current=#{current_tempo.round(2)} " \
                          "requirement=#{task_requirement.round(2)} " \
                          "mismatch=#{record.mismatch.round(3)} " \
                          "label=#{record.mismatch_label}")
                record.to_h
              end

              def adapt_tempo(domain:, target:, **)
                record = tempo_engine.adapt_tempo(domain: domain, target: target)
                unless record
                  log.debug("[cognitive_tempo] adapt: no records for domain=#{domain}")
                  return { adapted: false, domain: domain }
                end

                log.debug("[cognitive_tempo] adapted: domain=#{domain} current=#{record.current_tempo.round(2)} target=#{target.round(2)}")
                { adapted: true }.merge(record.to_h)
              end

              def tempo_status(domain: nil, **)
                if domain
                  record = tempo_engine.records[domain]&.last
                  if record
                    log.debug("[cognitive_tempo] status: domain=#{domain} tempo=#{record.current_tempo.round(2)} mismatch=#{record.mismatch_label}")
                    { found: true }.merge(record.to_h)
                  else
                    log.debug("[cognitive_tempo] status: domain=#{domain} not found")
                    { found: false, domain: domain }
                  end
                else
                  report = tempo_engine.tempo_report
                  log.debug("[cognitive_tempo] report: domains=#{report[:domains].size} avg_mismatch=#{report[:average_mismatch].round(3)}")
                  report
                end
              end

              def domains_in_sync(**)
                result = tempo_engine.domains_in_sync
                log.debug("[cognitive_tempo] in_sync: count=#{result.size}")
                { domains: result, count: result.size }
              end

              def domains_mismatched(**)
                result = tempo_engine.domains_mismatched
                log.debug("[cognitive_tempo] mismatched: count=#{result.size}")
                { domains: result, count: result.size }
              end

              def tempo_report(**)
                report = tempo_engine.tempo_report
                log.debug("[cognitive_tempo] report: total_records=#{report[:total_records]}")
                report
              end

              def run_tempo_adaptation(**)
                mismatched = tempo_engine.domains_mismatched
                adapted = mismatched.filter_map do |domain|
                  latest = tempo_engine.records[domain]&.last
                  next unless latest

                  record = tempo_engine.adapt_tempo(domain: domain, target: latest.baseline_tempo)
                  record&.to_h
                end

                log.info("[cognitive_tempo] adaptation cycle: #{adapted.size}/#{mismatched.size} domains adapted")
                { adapted: adapted.size, domains: mismatched.size, results: adapted }
              rescue StandardError => e
                log.error("[cognitive_tempo] run_tempo_adaptation failed: #{e.message}")
                { adapted: 0, domains: 0, error: e.message }
              end

              private

              def tempo_engine
                @tempo_engine ||= Helpers::TempoEngine.new
              end
            end
          end
        end
      end
    end
  end
end
