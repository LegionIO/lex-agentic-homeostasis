# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Furnace
          module Runners
            module CognitiveFurnace
              extend self

              include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                          Legion::Extensions::Helpers.const_defined?(:Lex, false)

              def add_ore(ore_type: nil, domain: nil, content: nil, purity: 0.5, impurity: nil, engine: nil, **)
                return { success: false, reason: :missing_ore_type } unless ore_type
                return { success: false, reason: :missing_domain }   unless domain
                return { success: false, reason: :missing_content }  unless content

                unless Helpers::Constants::ORE_TYPES.include?(ore_type.to_sym)
                  return { success: false, reason: :invalid_ore_type, valid: Helpers::Constants::ORE_TYPES }
                end

                result = furnace(engine).add_ore(
                  ore_type: ore_type.to_sym,
                  domain:   domain,
                  content:  content,
                  purity:   purity.to_f,
                  impurity: impurity&.to_f
                )

                log.debug("[furnace] add_ore: type=#{ore_type} domain=#{domain} added=#{result[:added]}")
                result[:added] ? { success: true }.merge(result) : { success: false }.merge(result)
              rescue ArgumentError => e
                { success: false, reason: :argument_error, message: e.message }
              end

              def create_crucible(capacity: 10, temperature: 0.0, engine: nil, **)
                result = furnace(engine).create_crucible(
                  capacity:    capacity.to_i,
                  temperature: temperature.to_f
                )

                log.debug("[furnace] create_crucible: capacity=#{capacity} created=#{result[:created]}")
                result[:created] ? { success: true }.merge(result) : { success: false }.merge(result)
              rescue ArgumentError => e
                { success: false, reason: :argument_error, message: e.message }
              end

              def load_ore(ore_id: nil, crucible_id: nil, engine: nil, **)
                return { success: false, reason: :missing_ore_id }      unless ore_id
                return { success: false, reason: :missing_crucible_id } unless crucible_id

                result = furnace(engine).load_ore(ore_id: ore_id, crucible_id: crucible_id)
                log.debug("[furnace] load_ore: ore=#{ore_id[0..7]} crucible=#{crucible_id[0..7]} loaded=#{result[:loaded]}")
                result[:loaded] ? { success: true }.merge(result) : { success: false }.merge(result)
              rescue ArgumentError => e
                { success: false, reason: :argument_error, message: e.message }
              end

              def heat(crucible_id: nil, rate: Helpers::Constants::HEAT_RATE, engine: nil, **)
                return { success: false, reason: :missing_crucible_id } unless crucible_id

                result = furnace(engine).heat_crucible(crucible_id: crucible_id, rate: rate.to_f)
                log.debug("[furnace] heat: crucible=#{crucible_id[0..7]} after=#{result[:after]} label=#{result[:label]}")
                result[:heated] ? { success: true }.merge(result) : { success: false }.merge(result)
              rescue ArgumentError => e
                { success: false, reason: :argument_error, message: e.message }
              end

              def smelt(crucible_id: nil, alloy_type: nil, engine: nil, **)
                return { success: false, reason: :missing_crucible_id } unless crucible_id

                alloy_sym = alloy_type&.to_sym
                if alloy_sym && !Helpers::Constants::ALLOY_TYPES.include?(alloy_sym)
                  return { success: false, reason: :invalid_alloy_type, valid: Helpers::Constants::ALLOY_TYPES }
                end

                result = furnace(engine).smelt(crucible_id: crucible_id, alloy_type: alloy_sym)
                log.debug("[furnace] smelt: crucible=#{crucible_id[0..7]} smelted=#{result[:smelted]}")
                result[:smelted] ? { success: true }.merge(result) : { success: false }.merge(result)
              rescue ArgumentError => e
                { success: false, reason: :argument_error, message: e.message }
              end

              def list_ores(limit: 50, engine: nil, **)
                fe = furnace(engine)
                ores = fe.ores.values.first(limit.to_i).map(&:to_h)
                log.debug("[furnace] list_ores: count=#{ores.size}")
                { success: true, ores: ores, total: fe.ores.size }
              rescue ArgumentError => e
                { success: false, reason: :argument_error, message: e.message }
              end

              def furnace_status(engine: nil, **)
                report = furnace(engine).furnace_report
                log.debug("[furnace] status: ores=#{report[:ore_count]} crucibles=#{report[:crucible_count]} alloys=#{report[:alloy_count]}")
                { success: true, report: report }
              rescue ArgumentError => e
                { success: false, reason: :argument_error, message: e.message }
              end

              private

              def furnace(engine)
                return engine if engine.is_a?(Helpers::FurnaceEngine)

                @furnace ||= Helpers::FurnaceEngine.new
              end

              def log_debug(msg)
                log.debug(msg)
              end
            end
          end
        end
      end
    end
  end
end
