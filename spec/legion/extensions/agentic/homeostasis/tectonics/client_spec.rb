# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tectonics::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a default TectonicEngine' do
      expect(client.engine).to be_a(Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::TectonicEngine)
    end

    it 'accepts injected engine' do
      custom = Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::TectonicEngine.new
      c      = described_class.new(engine: custom)
      expect(c.engine).to be(custom)
    end
  end

  describe 'runner methods via client' do
    it 'responds to create_plate' do
      expect(client).to respond_to(:create_plate)
    end

    it 'responds to drift_tick' do
      expect(client).to respond_to(:drift_tick)
    end

    it 'responds to resolve_collision' do
      expect(client).to respond_to(:resolve_collision)
    end

    it 'responds to trigger_earthquake' do
      expect(client).to respond_to(:trigger_earthquake)
    end

    it 'responds to tectonic_status' do
      expect(client).to respond_to(:tectonic_status)
    end
  end

  describe 'full workflow' do
    it 'creates plates and runs a tick' do
      client.create_plate(domain: :ethics, content: 'Truth matters', mass: 0.7)
      client.create_plate(domain: :ethics, content: 'Context shapes truth', mass: 0.5)
      result = client.drift_tick
      expect(result[:success]).to be(true)
    end

    it 'creates a plate and triggers an earthquake' do
      pid = client.create_plate(domain: :science, content: 'Evolution is fact', mass: 0.9)[:plate_id]
      result = client.trigger_earthquake(plate_id: pid, magnitude: 2.5)
      expect(result[:success]).to be(true)
    end

    it 'tectonic_status reflects created plates' do
      client.create_plate(domain: :ethics, content: 'x', mass: 0.6)
      client.create_plate(domain: :ethics, content: 'y', mass: 0.6)
      status = client.tectonic_status
      expect(status[:total_plates]).to eq(2)
    end

    it 'resolves a collision between two close plates' do
      pa = client.create_plate(domain: :ethics, content: 'a', mass: 0.8, position: { x: 0.0, y: 0.0 })[:plate_id]
      pb = client.create_plate(domain: :ethics, content: 'b', mass: 0.6, position: { x: 0.05, y: 0.0 })[:plate_id]
      result = client.resolve_collision(plate_a_id: pa, plate_b_id: pb, boundary_type: :transform)
      expect(result[:success]).to be(true)
    end
  end
end
