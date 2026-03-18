# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tectonics::Runners::CognitiveTectonics do
  let(:engine)  { Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::TectonicEngine.new }
  let(:runner)  { Object.new.extend(described_module) }

  let(:plate_a_id) do
    engine.create_plate(domain: :ethics, content: 'Honesty is paramount',
                        mass: 0.8, position: { x: 0.0, y: 0.0 })[:plate_id]
  end
  let(:plate_b_id) do
    engine.create_plate(domain: :ethics, content: 'White lies are acceptable',
                        mass: 0.5, position: { x: 0.05, y: 0.0 })[:plate_id]
  end

  def described_module
    Legion::Extensions::Agentic::Homeostasis::Tectonics::Runners::CognitiveTectonics
  end

  describe '#create_plate' do
    it 'creates a plate successfully' do
      result = runner.create_plate(domain: :science, content: 'Empiricism', engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:plate_id]).not_to be_nil
    end

    it 'returns failure when domain is missing' do
      result = runner.create_plate(content: 'test', engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to match(/domain/)
    end

    it 'returns failure when content is missing' do
      result = runner.create_plate(domain: :test, engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to match(/content/)
    end

    it 'passes mass to engine' do
      result = runner.create_plate(domain: :test, content: 'x', mass: 0.9, engine: engine)
      expect(engine.plates[result[:plate_id]].mass).to eq(0.9)
    end

    it 'accepts extra kwargs without error' do
      result = runner.create_plate(domain: :test, content: 'x', engine: engine, extra_key: 'ignored')
      expect(result[:success]).to be(true)
    end
  end

  describe '#drift_tick' do
    before { plate_a_id && plate_b_id }

    it 'returns success' do
      result = runner.drift_tick(engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'reports plates_moved' do
      result = runner.drift_tick(engine: engine)
      expect(result[:plates_moved]).to be >= 2
    end

    it 'defaults dt to 1.0 when not given' do
      result = runner.drift_tick(engine: engine)
      expect(result).to have_key(:plates_moved)
    end

    it 'accepts custom delta_t' do
      result = runner.drift_tick(delta_t: 0.5, engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '#resolve_collision' do
    before { plate_a_id && plate_b_id }

    it 'resolves a convergent collision' do
      result = runner.resolve_collision(
        plate_a_id: plate_a_id, plate_b_id: plate_b_id,
        boundary_type: :convergent, engine: engine
      )
      expect(result[:success]).to be(true)
      expect(result[:outcome]).to eq(:merged)
    end

    it 'returns failure when plate_a_id is missing' do
      result = runner.resolve_collision(plate_b_id: plate_b_id, boundary_type: :convergent, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'returns failure when plate_b_id is missing' do
      result = runner.resolve_collision(plate_a_id: plate_a_id, boundary_type: :convergent, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'returns failure for unknown boundary type' do
      result = runner.resolve_collision(
        plate_a_id: plate_a_id, plate_b_id: plate_b_id,
        boundary_type: :volcanic, engine: engine
      )
      expect(result[:success]).to be(false)
    end

    it 'defaults boundary_type to :convergent' do
      result = runner.resolve_collision(plate_a_id: plate_a_id, plate_b_id: plate_b_id, engine: engine)
      expect(result[:boundary_type]).to eq(:convergent)
    end
  end

  describe '#trigger_earthquake' do
    before { plate_a_id }

    it 'triggers an earthquake' do
      result = runner.trigger_earthquake(plate_id: plate_a_id, magnitude: 2.0, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:event_id]).not_to be_nil
    end

    it 'returns failure when plate_id is missing' do
      result = runner.trigger_earthquake(magnitude: 1.0, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'returns failure for unknown plate' do
      result = runner.trigger_earthquake(plate_id: 'ghost', magnitude: 1.0, engine: engine)
      expect(result[:success]).to be(false)
    end

    it 'defaults magnitude to 1.0 when not specified' do
      result = runner.trigger_earthquake(plate_id: plate_a_id, engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '#tectonic_status' do
    before { plate_a_id && plate_b_id }

    it 'returns success' do
      result = runner.tectonic_status(engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'includes total_plates' do
      result = runner.tectonic_status(engine: engine)
      expect(result[:total_plates]).to eq(2)
    end

    it 'includes seismic_events count' do
      runner.trigger_earthquake(plate_id: plate_a_id, magnitude: 1.5, engine: engine)
      result = runner.tectonic_status(engine: engine)
      expect(result[:seismic_events]).to eq(1)
    end

    it 'includes active_faults' do
      result = runner.tectonic_status(engine: engine)
      expect(result).to have_key(:active_faults)
    end
  end

  describe 'default engine isolation' do
    it 'each runner instance has its own default engine' do
      r1 = Object.new.extend(described_module)
      r2 = Object.new.extend(described_module)
      r1.create_plate(domain: :test, content: 'a')
      expect(r2.tectonic_status[:total_plates]).to eq(0)
    end
  end
end
