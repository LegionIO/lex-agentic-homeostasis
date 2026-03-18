# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Core
          module Helpers
            class AllostaticLoad
              attr_reader :load, :history, :peak_load

              def initialize
                @load = 0.0
                @peak_load = 0.0
                @history = []
              end

              def update(regulator)
                in_tolerance, deviating = regulator.setpoints.values.partition(&:within_tolerance?)

                accumulation = deviating.sum { |sp| sp.deviation_ratio * Constants::ALLOSTATIC_ACCUMULATION }
                recovery = in_tolerance.size * Constants::ALLOSTATIC_DECAY_RATE

                @load = (@load + accumulation - recovery).clamp(0.0, 1.0)
                @peak_load = [@peak_load, @load].max

                @history << { load: @load, deviating: deviating.size, at: Time.now.utc }
                @history = @history.last(Constants::MAX_ALLOSTATIC_HISTORY)

                @load
              end

              def classification
                if @load <= Constants::ALLOSTATIC_LOAD_HEALTHY
                  :healthy
                elsif @load <= Constants::ALLOSTATIC_LOAD_ELEVATED
                  :elevated
                elsif @load <= Constants::ALLOSTATIC_LOAD_CRITICAL
                  :high
                else
                  :critical
                end
              end

              def recovering?
                recent = @history.last(5)
                return false if recent.size < 3

                recent.last[:load] < recent.first[:load]
              end

              def trend(window: 20)
                recent = @history.last(window)
                return :insufficient_data if recent.size < 3

                loads = recent.map { |h| h[:load] }
                avg_first_half = loads[0...(loads.size / 2)].sum / (loads.size / 2).to_f
                avg_second_half = loads[(loads.size / 2)..].sum / (loads.size - (loads.size / 2)).to_f

                delta = avg_second_half - avg_first_half
                if delta > 0.05
                  :accumulating
                elsif delta < -0.05
                  :recovering
                else
                  :stable
                end
              end

              def reset
                @load = 0.0
                @history.clear
              end

              def to_h
                {
                  load:           @load,
                  peak_load:      @peak_load,
                  classification: classification,
                  recovering:     recovering?,
                  trend:          trend,
                  history_size:   @history.size
                }
              end
            end
          end
        end
      end
    end
  end
end
