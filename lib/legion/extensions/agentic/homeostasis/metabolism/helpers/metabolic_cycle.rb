# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Metabolism
          module Helpers
            class MetabolicCycle
              attr_reader :id, :cycle_count, :operations_log, :energy_spent_this_cycle, :started_at, :completed_at

              def initialize
                @id                    = SecureRandom.uuid
                @cycle_count           = 0
                @operations_log        = []
                @energy_spent_this_cycle = 0.0
                @started_at            = Time.now.utc
                @completed_at          = nil
              end

              def record_operation(operation_type:, energy_spent:)
                @operations_log << {
                  operation_type: operation_type,
                  energy_spent:   energy_spent.round(10),
                  recorded_at:    Time.now.utc
                }
                @energy_spent_this_cycle += energy_spent
                @cycle_count += 1
              end

              def complete!
                @completed_at = Time.now.utc
                to_h
              end

              def duration_seconds
                return nil unless @completed_at

                (@completed_at - @started_at).round(4)
              end

              def average_energy_per_operation
                return 0.0 if @cycle_count.zero?

                (@energy_spent_this_cycle / @cycle_count).round(10)
              end

              def to_h
                {
                  id:                      @id,
                  cycle_count:             @cycle_count,
                  energy_spent_this_cycle: @energy_spent_this_cycle.round(10),
                  average_per_operation:   average_energy_per_operation,
                  operations_log:          @operations_log,
                  started_at:              @started_at,
                  completed_at:            @completed_at,
                  duration_seconds:        duration_seconds
                }
              end
            end
          end
        end
      end
    end
  end
end
