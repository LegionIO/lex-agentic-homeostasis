# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module FossilFuel
          module Runners
            module CognitiveFossilFuel
              extend self

              def create_reserve(fuel_type:, domain:, content:,
                                 volume: nil, quality: nil, engine: nil, **)
                eng = resolve_engine(engine)
                r   = eng.create_reserve(fuel_type: fuel_type, domain: domain,
                                         content: content, volume: volume, quality: quality)
                { success: true, reserve: r.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def extract(reserve_id:, rate: nil, engine: nil, **)
                eng  = resolve_engine(engine)
                opts = { reserve_id: reserve_id }
                opts[:rate] = rate if rate
                result = eng.extract(**opts)
                { success: true, reserve: result[:reserve].to_h,
                  extracted: result[:extracted] }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def combust(reserve_id:, amount: nil, grade: :crude, engine: nil, **)
                eng    = resolve_engine(engine)
                result = eng.combust(reserve_id: reserve_id, amount: amount, grade: grade)
                { success: true, combustion: result[:combustion].to_h,
                  reserve: result[:reserve].to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def list_reserves(engine: nil, fuel_type: nil, **)
                eng     = resolve_engine(engine)
                results = eng.all_reserves
                results = results.select { |r| r.fuel_type == fuel_type.to_sym } if fuel_type
                { success: true, reserves: results.map(&:to_h), count: results.size }
              end

              def fuel_status(engine: nil, **)
                eng = resolve_engine(engine)
                { success: true, report: eng.fuel_report }
              end

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              private

              def resolve_engine(engine)
                engine || default_engine
              end

              def default_engine
                @default_engine ||= Helpers::FuelEngine.new
              end
            end
          end
        end
      end
    end
  end
end
