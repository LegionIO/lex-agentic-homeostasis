# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Surplus
          module Runners
            module Surplus
              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def surplus_status(**)
                report = surplus_engine.surplus_report
                log.debug("[cognitive_surplus] status surplus=#{report[:available_surplus].round(2)} " \
                          "label=#{report[:surplus_label]} quality=#{report[:quality_label]}")
                report
              end

              def allocate_surplus(activity_type:, amount: Helpers::Constants::SURPLUS_THRESHOLD, **)
                result = surplus_engine.allocate!(activity_type: activity_type, amount: amount)
                if result[:allocated]
                  log.info("[cognitive_surplus] allocated #{amount.round(2)} to " \
                           "#{activity_type} quality=#{result[:quality].round(2)} id=#{result[:allocation_id][0..7]}")
                else
                  log.debug("[cognitive_surplus] allocate failed: #{result[:reason]}")
                end
                result
              end

              def release_surplus(allocation_id:, **)
                result = surplus_engine.release!(allocation_id: allocation_id)
                if result[:released]
                  log.info("[cognitive_surplus] released allocation #{allocation_id[0..7]} amount=#{result[:amount].round(2)}")
                else
                  log.debug("[cognitive_surplus] release failed: #{result[:reason]} id=#{allocation_id[0..7]}")
                end
                result
              end

              def commit_capacity(amount:, **)
                result = surplus_engine.commit!(amount: amount)
                log.debug("[cognitive_surplus] committed #{amount.round(2)} committed=#{result[:committed].round(2)} " \
                          "surplus=#{result[:available_surplus].round(2)}")
                result
              end

              def uncommit_capacity(amount:, **)
                result = surplus_engine.uncommit!(amount: amount)
                log.debug("[cognitive_surplus] uncommitted #{amount.round(2)} committed=#{result[:committed].round(2)} " \
                          "surplus=#{result[:available_surplus].round(2)}")
                result
              end

              def replenish_surplus(**)
                result = surplus_engine.replenish!
                log.debug("[cognitive_surplus] replenished gained=#{result[:gained].round(2)} " \
                          "surplus=#{result[:available_surplus].round(2)}")
                result
              end

              def deplete_surplus(amount:, **)
                result = surplus_engine.deplete!(amount: amount)
                log.debug("[cognitive_surplus] depleted amount=#{result[:amount].round(2)} " \
                          "surplus=#{result[:available_surplus].round(2)}")
                result
              end

              def surplus_allocations(**)
                allocations = surplus_engine.allocations.values.select(&:active?).map(&:to_h)
                log.debug("[cognitive_surplus] allocations count=#{allocations.size}")
                { allocations: allocations, count: allocations.size }
              end

              private

              def surplus_engine
                @surplus_engine ||= Helpers::SurplusEngine.new
              end
            end
          end
        end
      end
    end
  end
end
