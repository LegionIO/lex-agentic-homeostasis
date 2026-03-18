# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Cocoon
          module Helpers
            class Incubator
              include Constants

              def initialize
                @cocoons = {}
              end

              def create_cocoon(cocoon_type:, domain:, content: '', maturity: nil, protection: nil)
                return nil unless COCOON_TYPES.include?(cocoon_type.to_sym)

                prune_cocoons
                cocoon = Cocoon.new(
                  cocoon_type: cocoon_type,
                  domain:      domain,
                  content:     content,
                  maturity:    maturity,
                  protection:  protection
                )
                @cocoons[cocoon.id] = cocoon
                cocoon
              end

              def gestate_all!(rate = MATURITY_RATE)
                @cocoons.each_value { |c| c.gestate!(rate) unless c.stage == :emerged }
                self
              end

              def harvest_ready
                ready = @cocoons.values.select(&:ready?)
                results = ready.map(&:emerge!)
                ready.each { |c| @cocoons.delete(c.id) if c.stage == :emerged }
                results
              end

              def force_emerge(id)
                cocoon = @cocoons[id]
                return { success: false, error: 'cocoon not found' } unless cocoon

                result = cocoon.expose!
                @cocoons.delete(id) if cocoon.stage == :emerged
                result
              end

              def by_stage(stage)
                @cocoons.values.select { |c| c.stage == stage.to_sym }
              end

              def most_mature(limit: 5)
                @cocoons.values.sort_by { |c| -c.maturity }.first(limit)
              end

              def incubator_report
                total    = @cocoons.size
                by_s     = Hash.new(0)
                @cocoons.each_value { |c| by_s[c.stage] += 1 }
                avg_mat  = total.zero? ? 0.0 : (@cocoons.values.sum(&:maturity) / total).round(10)
                avg_prot = total.zero? ? 0.0 : (@cocoons.values.sum(&:protection) / total).round(10)

                {
                  total_cocoons:      total,
                  average_maturity:   avg_mat,
                  maturity_label:     Constants.label_for(MATURITY_LABELS, avg_mat),
                  average_protection: avg_prot,
                  stage_distribution: by_s,
                  ready_count:        by_stage(:ready).size,
                  most_mature:        most_mature(limit: 3).map(&:to_h)
                }
              end

              def to_h
                {
                  total_cocoons:    @cocoons.size,
                  average_maturity: @cocoons.empty? ? 0.0 : (@cocoons.values.sum(&:maturity) / @cocoons.size).round(10)
                }
              end

              private

              def prune_cocoons
                return if @cocoons.size < MAX_COCOONS

                emerged = @cocoons.values.select { |c| c.stage == :emerged }
                emerged.each { |c| @cocoons.delete(c.id) }
                return if @cocoons.size < MAX_COCOONS

                sorted = @cocoons.values.sort_by(&:maturity)
                to_remove = sorted.first(@cocoons.size - MAX_COCOONS + 1)
                to_remove.each { |c| @cocoons.delete(c.id) }
              end
            end
          end
        end
      end
    end
  end
end
