# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tempo
          module Helpers
            class TempoRecord
              include Constants

              attr_reader :id, :domain, :baseline_tempo, :current_tempo,
                          :task_tempo_requirement, :created_at

              def initialize(domain:, baseline_tempo: Constants::DEFAULT_TEMPO,
                             current_tempo: Constants::DEFAULT_TEMPO,
                             task_tempo_requirement: Constants::DEFAULT_TEMPO)
                @id                    = SecureRandom.uuid
                @domain                = domain
                @baseline_tempo        = baseline_tempo.clamp(0.0, 1.0)
                @current_tempo         = current_tempo.clamp(0.0, 1.0)
                @task_tempo_requirement = task_tempo_requirement.clamp(0.0, 1.0)
                @created_at = Time.now.utc
              end

              def mismatch
                (@current_tempo - @task_tempo_requirement).abs.round(10)
              end

              def accelerate!(amount: Constants::TEMPO_ADJUSTMENT)
                @current_tempo = (@current_tempo + amount).clamp(0.0, 1.0)
                self
              end

              def decelerate!(amount: Constants::TEMPO_ADJUSTMENT)
                @current_tempo = (@current_tempo - amount).clamp(0.0, 1.0)
                self
              end

              def adapt_to!(target:, rate: Constants::TEMPO_ADJUSTMENT)
                delta = (target - @current_tempo).clamp(-rate, rate)
                @current_tempo = (@current_tempo + delta).clamp(0.0, 1.0)
                self
              end

              def tempo_label
                label_for(@current_tempo, Constants::TEMPO_LABELS)
              end

              def mismatch_label
                label_for(mismatch, Constants::MISMATCH_LABELS)
              end

              def to_h
                {
                  id:                     @id,
                  domain:                 @domain,
                  baseline_tempo:         @baseline_tempo.round(10),
                  current_tempo:          @current_tempo.round(10),
                  task_tempo_requirement: @task_tempo_requirement.round(10),
                  mismatch:               mismatch,
                  tempo_label:            tempo_label,
                  mismatch_label:         mismatch_label,
                  created_at:             @created_at
                }
              end

              private

              def label_for(value, table)
                table.each { |range, label| return label if range.cover?(value) }
                table.values.last
              end
            end
          end
        end
      end
    end
  end
end
