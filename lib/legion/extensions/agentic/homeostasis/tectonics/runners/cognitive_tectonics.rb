# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tectonics
          module Runners
            module CognitiveTectonics
              extend self

              include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

              def create_plate(domain: nil, content: nil, mass: 0.5, drift_vector: nil, position: nil, engine: nil, **)
                raise ArgumentError, 'domain is required'  if domain.nil?
                raise ArgumentError, 'content is required' if content.nil?

                tectonic_engine(engine).create_plate(
                  domain:       domain,
                  content:      content,
                  mass:         mass,
                  drift_vector: drift_vector,
                  position:     position
                )
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def drift_tick(delta_t: 1.0, engine: nil, **)
                tectonic_engine(engine).drift_tick!(delta_t)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def resolve_collision(plate_a_id: nil, plate_b_id: nil, boundary_type: :convergent, engine: nil, **)
                raise ArgumentError, 'plate_a_id is required' if plate_a_id.nil?
                raise ArgumentError, 'plate_b_id is required' if plate_b_id.nil?

                tectonic_engine(engine).resolve_collision(
                  plate_a_id:    plate_a_id,
                  plate_b_id:    plate_b_id,
                  boundary_type: boundary_type
                )
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def trigger_earthquake(plate_id: nil, magnitude: 1.0, engine: nil, **)
                raise ArgumentError, 'plate_id is required' if plate_id.nil?

                tectonic_engine(engine).trigger_earthquake(plate_id: plate_id, magnitude: magnitude)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def tectonic_status(engine: nil, **)
                eng    = tectonic_engine(engine)
                report = eng.tectonic_report
                { success: true }.merge(report)
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              private

              def tectonic_engine(engine)
                engine || @tectonic_engine ||= Helpers::TectonicEngine.new
              end
            end
          end
        end
      end
    end
  end
end
