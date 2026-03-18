# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Cocoon
          module Runners
            module CognitiveCocoon
              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_cocoon(cocoon_type:, domain:, content: '', maturity: nil,
                                protection: nil, engine: nil, **)
                eng = engine || @default_engine
                cocoon = eng.create_cocoon(
                  cocoon_type: cocoon_type,
                  domain:      domain,
                  content:     content,
                  maturity:    maturity,
                  protection:  protection
                )
                { success: true, cocoon: cocoon.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def gestate_all(rate: nil, engine: nil, **)
                eng = engine || @default_engine
                eng.gestate_all!(rate || Helpers::Constants::MATURITY_RATE)
                { success: true }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def harvest_ready(engine: nil, **)
                eng = engine || @default_engine
                emerged = eng.harvest_ready
                { success: true, count: emerged.size, emerged: emerged }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def force_emerge(id:, engine: nil, **)
                eng = engine || @default_engine
                result = eng.force_emerge(id)
                result.merge(success: result[:error].nil?)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def cocoon_status(engine: nil, **)
                eng = engine || @default_engine
                report = eng.incubator_report
                { success: true, **report }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def list_by_stage(stage:, engine: nil, **)
                eng = engine || @default_engine
                cocoons = eng.by_stage(stage)
                { success: true, stage: stage, count: cocoons.size, cocoons: cocoons.map(&:to_h) }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end
            end
          end
        end
      end
    end
  end
end
