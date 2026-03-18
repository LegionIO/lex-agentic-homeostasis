# frozen_string_literal: true

module Legion
  module Extensions
    module Agentic
      module Homeostasis
        module Tectonics
          module Helpers
            module TectonicBoundaries
              private

              def resolve_convergent(plate_a, plate_b)
                combined = ((plate_a.mass + plate_b.mass) / 2.0).clamp(0.0, 1.0)
                plate_a.mass = combined
                plate_b.mass = combined
                avg_drift = {
                  x: ((plate_a.drift_vector[:x] + plate_b.drift_vector[:x]) / 2.0).round(10),
                  y: ((plate_a.drift_vector[:y] + plate_b.drift_vector[:y]) / 2.0).round(10)
                }
                plate_a.drift_vector = avg_drift
                plate_b.drift_vector = avg_drift
                { success: true, boundary_type: :convergent, outcome: :merged, new_mass: combined }
              end

              def resolve_divergent(plate_a, plate_b)
                split_mass = (plate_a.mass * 0.5).round(10)
                plate_a.mass = split_mass
                plate_b.mass = split_mass
                plate_a.drift_vector = { x: -plate_a.drift_vector.fetch(:x, 0.0), y: plate_a.drift_vector.fetch(:y, 0.0) }
                plate_b.drift_vector = { x: plate_b.drift_vector.fetch(:x, 0.0), y: -plate_b.drift_vector.fetch(:y, 0.0) }
                { success: true, boundary_type: :divergent, outcome: :split, new_mass: split_mass }
              end

              def resolve_transform(plate_a, plate_b)
                stress = (plate_a.mass * plate_b.mass * 0.5).round(10)
                plate_a.accumulate_stress!(stress)
                plate_b.accumulate_stress!(stress)
                check_stress_quake(plate_a)
                check_stress_quake(plate_b)
                { success: true, boundary_type: :transform, outcome: :friction, stress_added: stress }
              end

              def check_stress_quake(plate)
                return unless plate.stress_accumulation >= Constants::STRESS_QUAKE_TRIGGER

                trigger_earthquake(plate_id: plate.id, magnitude: plate.stress_accumulation)
              end

              def nearby_plates(plate, exclude_id:)
                @plates.values.select do |p|
                  p.active? && p.id != exclude_id && plate.distance_to(p) < 5.0
                end
              end

              def record_seismic_event(event)
                @seismic_history << event
                @seismic_history.shift if @seismic_history.size > Constants::MAX_QUAKES
              end

              def update_active_faults(plate_a_id, plate_b_id, boundary_type)
                existing = @active_faults.find { |f| fault_matches?(f, plate_a_id, plate_b_id) }
                if existing
                  existing[:boundary_type] = boundary_type
                  existing[:last_activity] = Time.now.utc
                else
                  @active_faults << { plate_a_id: plate_a_id, plate_b_id: plate_b_id,
                                      boundary_type: boundary_type, last_activity: Time.now.utc }
                end
              end

              def fault_matches?(fault, id_a, id_b)
                (fault[:plate_a_id] == id_a && fault[:plate_b_id] == id_b) ||
                  (fault[:plate_a_id] == id_b && fault[:plate_b_id] == id_a)
              end

              def remove_faults_for(plate_id)
                @active_faults.reject! { |f| f[:plate_a_id] == plate_id || f[:plate_b_id] == plate_id }
              end

              def avg_mass(plates)
                return 0.0 if plates.empty?

                (plates.sum(&:mass) / plates.size.to_f).round(10)
              end

              def recent_earthquakes(count)
                @seismic_history.last(count).map(&:to_h)
              end
            end

            class TectonicEngine
              include Constants
              include TectonicBoundaries

              attr_reader :plates, :seismic_history, :active_faults

              def initialize
                @plates          = {}
                @seismic_history = []
                @active_faults   = []
              end

              def create_plate(domain:, content:, mass: 0.5, drift_vector: nil, position: nil, **)
                raise ArgumentError, 'plate limit reached' if @plates.size >= Constants::MAX_PLATES

                plate = BeliefPlate.new(domain: domain, content: content,
                                        mass: mass, drift_vector: drift_vector, position: position)
                @plates[plate.id] = plate
                { success: true, plate_id: plate.id, plate: plate.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def drift_tick!(delta_t = 1.0, **)
                moved = 0
                @plates.each_value do |plate|
                  next unless plate.active?

                  plate.drift!(delta_t)
                  moved += 1
                end
                collisions = detect_collisions
                { success: true, plates_moved: moved, collisions_detected: collisions.size, collisions: collisions }
              end

              def detect_collisions
                active = @plates.values.select(&:active?)
                pairs  = active.combination(2).select { |a, b| a.distance_to(b) < Constants::COLLISION_THRESHOLD }
                pairs.map { |a, b| { plate_a_id: a.id, plate_b_id: b.id, distance: a.distance_to(b) } }
              end

              def resolve_collision(plate_a_id:, plate_b_id:, boundary_type:, **)
                raise ArgumentError, "unknown boundary type: #{boundary_type}" unless Constants::BOUNDARY_TYPES.include?(boundary_type)

                plate_a = @plates[plate_a_id]
                plate_b = @plates[plate_b_id]
                raise ArgumentError, "plate not found: #{plate_a_id}" unless plate_a
                raise ArgumentError, "plate not found: #{plate_b_id}" unless plate_b

                result = send(:"resolve_#{boundary_type}", plate_a, plate_b)
                update_active_faults(plate_a_id, plate_b_id, boundary_type)
                result
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def subduct(weaker_plate_id:, stronger_plate_id:, **)
                weaker   = @plates[weaker_plate_id]
                stronger = @plates[stronger_plate_id]
                raise ArgumentError, "plate not found: #{weaker_plate_id}"   unless weaker
                raise ArgumentError, "plate not found: #{stronger_plate_id}" unless stronger

                mass_absorbed = weaker.mass * 0.5
                stronger.mass = (stronger.mass + mass_absorbed).clamp(0.0, 1.0)
                weaker.subduct!
                remove_faults_for(weaker_plate_id)
                { success: true, subducted_plate_id: weaker_plate_id, mass_absorbed: mass_absorbed.round(10) }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def trigger_earthquake(plate_id:, magnitude:, **)
                plate = @plates[plate_id]
                raise ArgumentError, "plate not found: #{plate_id}" unless plate

                nearby = nearby_plates(plate, exclude_id: plate_id)
                event  = SeismicEvent.new(type: :earthquake, magnitude: magnitude,
                                          epicenter_plate_id: plate_id, affected_plate_ids: nearby.map(&:id))
                record_seismic_event(event)
                plate.release_stress!
                nearby.each { |p| p.accumulate_stress!(magnitude * 0.3) }
                { success: true, event_id: event.id, event: event.to_h }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def aftershock_cascade(event_id:, **)
                parent = @seismic_history.find { |e| e.id == event_id }
                raise ArgumentError, "event not found: #{event_id}" unless parent

                decayed_magnitude = (parent.magnitude * (1.0 - Constants::AFTERSHOCK_DECAY)).round(10)
                return { success: true, aftershocks: [], reason: :magnitude_too_low } if decayed_magnitude < 0.1

                aftershock = SeismicEvent.new(type: :aftershock, magnitude: decayed_magnitude,
                                              epicenter_plate_id: parent.epicenter_plate_id,
                                              affected_plate_ids: parent.affected_plate_ids,
                                              parent_event_id: event_id)
                record_seismic_event(aftershock)
                { success: true, aftershocks: [aftershock.to_h] }
              rescue ArgumentError => e
                { success: false, error: e.message }
              end

              def all_plates
                @plates.values.map(&:to_h)
              end

              def tectonic_report
                active_plates, subducted_plates = @plates.values.partition(&:active?)
                high_stress = active_plates.select { |p| p.stress_accumulation > 0.5 }
                {
                  total_plates:      @plates.size,
                  active_plates:     active_plates.size,
                  subducted_plates:  subducted_plates.size,
                  high_stress_count: high_stress.size,
                  seismic_events:    @seismic_history.size,
                  active_faults:     @active_faults.size,
                  avg_mass:          avg_mass(active_plates),
                  recent_quakes:     recent_earthquakes(5)
                }
              end
            end
          end
        end
      end
    end
  end
end
