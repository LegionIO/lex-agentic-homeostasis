# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::TectonicEngine do
  subject(:engine) { described_class.new }

  let(:plate_a_id) do
    engine.create_plate(domain: :ethics, content: 'Honesty matters',
                        mass: 0.8, position: { x: 0.0, y: 0.0 })[:plate_id]
  end
  let(:plate_b_id) do
    engine.create_plate(domain: :ethics, content: 'Deception is acceptable',
                        mass: 0.5, position: { x: 0.1, y: 0.0 })[:plate_id]
  end

  describe '#create_plate' do
    it 'returns success with plate_id' do
      result = engine.create_plate(domain: :science, content: 'Empiricism works', mass: 0.7)
      expect(result[:success]).to be(true)
      expect(result[:plate_id]).not_to be_nil
    end

    it 'stores the plate' do
      result = engine.create_plate(domain: :science, content: 'Empiricism works')
      expect(engine.plates[result[:plate_id]]).not_to be_nil
    end

    it 'returns plate hash in result' do
      result = engine.create_plate(domain: :ethics, content: 'Do no harm')
      expect(result[:plate]).to include(:id, :domain, :content, :mass)
    end

    it 'returns failure when plate limit exceeded' do
      51.times { |i| engine.create_plate(domain: :test, content: "belief #{i}") }
      result = engine.create_plate(domain: :test, content: 'overflow')
      expect(result[:success]).to be(false)
    end

    it 'respects custom position' do
      result = engine.create_plate(domain: :test, content: 'x', position: { x: 5.0, y: -2.0 })
      plate  = engine.plates[result[:plate_id]]
      expect(plate.position[:x]).to eq(5.0)
    end
  end

  describe '#drift_tick!' do
    before { plate_a_id && plate_b_id }

    it 'returns success' do
      result = engine.drift_tick!
      expect(result[:success]).to be(true)
    end

    it 'reports plates_moved count' do
      result = engine.drift_tick!
      expect(result[:plates_moved]).to be >= 2
    end

    it 'reports collisions_detected' do
      result = engine.drift_tick!
      expect(result).to have_key(:collisions_detected)
    end
  end

  describe '#detect_collisions' do
    it 'detects plates within COLLISION_THRESHOLD' do
      plate_a_id && plate_b_id
      collisions = engine.detect_collisions
      expect(collisions).not_to be_empty
    end

    it 'does not detect plates far apart' do
      engine.create_plate(domain: :a, content: 'x', position: { x: 0.0, y: 0.0 })
      engine.create_plate(domain: :b, content: 'y', position: { x: 100.0, y: 100.0 })
      collisions = engine.detect_collisions
      expect(collisions).to be_empty
    end

    it 'returns distance in collision record' do
      plate_a_id && plate_b_id
      c = engine.detect_collisions.first
      expect(c[:distance]).to be_a(Float)
    end
  end

  describe '#resolve_collision' do
    before { plate_a_id && plate_b_id }

    context 'with :convergent boundary' do
      it 'merges belief conviction' do
        result = engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :convergent)
        expect(result[:success]).to be(true)
        expect(result[:outcome]).to eq(:merged)
        expect(result[:new_mass]).to be_a(Float)
      end

      it 'equalises mass between plates' do
        engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :convergent)
        pa = engine.plates[plate_a_id]
        pb = engine.plates[plate_b_id]
        expect(pa.mass).to eq(pb.mass)
      end
    end

    context 'with :divergent boundary' do
      it 'splits belief conviction' do
        result = engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :divergent)
        expect(result[:success]).to be(true)
        expect(result[:outcome]).to eq(:split)
      end

      it 'reduces mass on both plates' do
        orig_a = engine.plates[plate_a_id].mass
        engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :divergent)
        expect(engine.plates[plate_a_id].mass).to be < orig_a
      end
    end

    context 'with :transform boundary' do
      it 'generates friction / stress' do
        result = engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :transform)
        expect(result[:success]).to be(true)
        expect(result[:outcome]).to eq(:friction)
        expect(result[:stress_added]).to be > 0
      end

      it 'accumulates stress on both plates' do
        engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :transform)
        expect(engine.plates[plate_a_id].stress_accumulation).to be > 0
        expect(engine.plates[plate_b_id].stress_accumulation).to be > 0
      end
    end

    it 'records the fault' do
      engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :convergent)
      expect(engine.active_faults).not_to be_empty
    end

    it 'returns failure for unknown boundary type' do
      result = engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :subterranean)
      expect(result[:success]).to be(false)
    end

    it 'returns failure for missing plate' do
      result = engine.resolve_collision(plate_a_id: 'no-such-id', plate_b_id: plate_b_id, boundary_type: :convergent)
      expect(result[:success]).to be(false)
    end
  end

  describe '#subduct' do
    before { plate_a_id && plate_b_id }

    it 'marks weaker plate as subducted' do
      engine.subduct(weaker_plate_id: plate_b_id, stronger_plate_id: plate_a_id)
      expect(engine.plates[plate_b_id].state).to eq(:subducted)
    end

    it 'transfers mass to stronger plate' do
      orig_mass = engine.plates[plate_a_id].mass
      engine.subduct(weaker_plate_id: plate_b_id, stronger_plate_id: plate_a_id)
      expect(engine.plates[plate_a_id].mass).to be > orig_mass
    end

    it 'returns mass_absorbed' do
      result = engine.subduct(weaker_plate_id: plate_b_id, stronger_plate_id: plate_a_id)
      expect(result[:mass_absorbed]).to be > 0
    end

    it 'returns failure for missing plate' do
      result = engine.subduct(weaker_plate_id: 'no-such', stronger_plate_id: plate_a_id)
      expect(result[:success]).to be(false)
    end

    it 'removes faults associated with subducted plate' do
      engine.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, boundary_type: :convergent)
      engine.subduct(weaker_plate_id: plate_b_id, stronger_plate_id: plate_a_id)
      engine.active_faults.each do |f|
        expect(f[:plate_a_id]).not_to eq(plate_b_id)
        expect(f[:plate_b_id]).not_to eq(plate_b_id)
      end
    end
  end

  describe '#trigger_earthquake' do
    before { plate_a_id }

    it 'creates a seismic event' do
      result = engine.trigger_earthquake(plate_id: plate_a_id, magnitude: 2.5)
      expect(result[:success]).to be(true)
      expect(result[:event_id]).not_to be_nil
    end

    it 'appends event to seismic_history' do
      engine.trigger_earthquake(plate_id: plate_a_id, magnitude: 2.5)
      expect(engine.seismic_history.size).to eq(1)
    end

    it 'releases stress from the epicenter plate' do
      engine.plates[plate_a_id].accumulate_stress!(0.8)
      engine.trigger_earthquake(plate_id: plate_a_id, magnitude: 2.5)
      expect(engine.plates[plate_a_id].stress_accumulation).to eq(0.0)
    end

    it 'returns failure for missing plate' do
      result = engine.trigger_earthquake(plate_id: 'ghost-plate', magnitude: 1.0)
      expect(result[:success]).to be(false)
    end
  end

  describe '#aftershock_cascade' do
    let(:event_id) do
      engine.trigger_earthquake(plate_id: plate_a_id, magnitude: 3.0)[:event_id]
    end

    before { plate_a_id }

    it 'generates an aftershock with decayed magnitude' do
      result = engine.aftershock_cascade(event_id: event_id)
      expect(result[:success]).to be(true)
      expect(result[:aftershocks]).not_to be_empty
      aftershock = result[:aftershocks].first
      expect(aftershock[:magnitude]).to be < 3.0
    end

    it 'aftershock has parent_event_id set' do
      result = engine.aftershock_cascade(event_id: event_id)
      expect(result[:aftershocks].first[:parent_event_id]).to eq(event_id)
    end

    it 'records the aftershock in seismic_history' do
      engine.aftershock_cascade(event_id: event_id)
      types = engine.seismic_history.map(&:type)
      expect(types).to include(:aftershock)
    end

    it 'skips aftershock when magnitude decays below 0.1' do
      small_id = engine.trigger_earthquake(plate_id: plate_a_id, magnitude: 0.1)[:event_id]
      result   = engine.aftershock_cascade(event_id: small_id)
      expect(result[:aftershocks]).to be_empty
    end

    it 'returns failure for missing event' do
      result = engine.aftershock_cascade(event_id: 'no-event')
      expect(result[:success]).to be(false)
    end
  end

  describe '#all_plates' do
    it 'returns array of plate hashes' do
      plate_a_id
      result = engine.all_plates
      expect(result).to be_an(Array)
      expect(result.first).to include(:id, :domain, :content, :mass, :state)
    end
  end

  describe '#tectonic_report' do
    before { plate_a_id && plate_b_id }

    it 'includes total_plates' do
      expect(engine.tectonic_report[:total_plates]).to eq(2)
    end

    it 'includes active_plates count' do
      expect(engine.tectonic_report[:active_plates]).to eq(2)
    end

    it 'includes seismic_events count' do
      engine.trigger_earthquake(plate_id: plate_a_id, magnitude: 1.5)
      expect(engine.tectonic_report[:seismic_events]).to eq(1)
    end

    it 'includes avg_mass' do
      expect(engine.tectonic_report[:avg_mass]).to be_a(Float)
    end

    it 'includes active_faults count' do
      expect(engine.tectonic_report[:active_faults]).to be_a(Integer)
    end

    it 'counts subducted plates separately' do
      engine.subduct(weaker_plate_id: plate_b_id, stronger_plate_id: plate_a_id)
      report = engine.tectonic_report
      expect(report[:subducted_plates]).to eq(1)
      expect(report[:active_plates]).to eq(1)
    end
  end

  describe 'seismic_history cap' do
    before { plate_a_id }

    it 'caps at MAX_QUAKES' do
      max = Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::Constants::MAX_QUAKES
      (max + 5).times { engine.trigger_earthquake(plate_id: plate_a_id, magnitude: 0.5) }
      expect(engine.seismic_history.size).to eq(max)
    end
  end
end
