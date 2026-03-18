# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::BeliefPlate do
  subject(:plate) { described_class.new(domain: :epistemology, content: 'Truth is objective') }

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(plate.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets domain' do
      expect(plate.domain).to eq(:epistemology)
    end

    it 'sets content' do
      expect(plate.content).to eq('Truth is objective')
    end

    it 'defaults mass to 0.5' do
      expect(plate.mass).to eq(0.5)
    end

    it 'clamps mass above 1.0 to 1.0' do
      p = described_class.new(domain: :test, content: 'x', mass: 1.5)
      expect(p.mass).to eq(1.0)
    end

    it 'clamps mass below 0.0 to 0.0' do
      p = described_class.new(domain: :test, content: 'x', mass: -0.1)
      expect(p.mass).to eq(0.0)
    end

    it 'defaults drift_vector to zero' do
      expect(plate.drift_vector).to eq({ x: 0.0, y: 0.0 })
    end

    it 'accepts custom drift_vector' do
      p = described_class.new(domain: :test, content: 'x', drift_vector: { x: 0.01, y: -0.02 })
      expect(p.drift_vector[:x]).to eq(0.01)
    end

    it 'assigns a random position when none given' do
      expect(plate.position).to have_key(:x)
      expect(plate.position).to have_key(:y)
    end

    it 'accepts custom position' do
      p = described_class.new(domain: :test, content: 'x', position: { x: 3.0, y: -1.0 })
      expect(p.position[:x]).to eq(3.0)
    end

    it 'initializes stress_accumulation to 0.0' do
      expect(plate.stress_accumulation).to eq(0.0)
    end

    it 'starts in :active state' do
      expect(plate.state).to eq(:active)
    end

    it 'records created_at' do
      expect(plate.created_at).to be_a(Time)
    end
  end

  describe '#drift!' do
    let(:drifting_plate) do
      described_class.new(domain: :test, content: 'x',
                          drift_vector: { x: 0.01, y: 0.02 },
                          position:     { x: 0.0, y: 0.0 })
    end

    it 'updates position by drift_vector * dt' do
      drifting_plate.drift!(1.0)
      expect(drifting_plate.position[:x]).to be_within(1e-9).of(0.01)
      expect(drifting_plate.position[:y]).to be_within(1e-9).of(0.02)
    end

    it 'scales by delta_t' do
      drifting_plate.drift!(2.0)
      expect(drifting_plate.position[:x]).to be_within(1e-9).of(0.02)
    end

    it 'does not drift when subducted' do
      drifting_plate.subduct!
      drifting_plate.drift!(1.0)
      expect(drifting_plate.position[:x]).to eq(0.0)
    end
  end

  describe '#accumulate_stress!' do
    it 'adds stress' do
      plate.accumulate_stress!(0.3)
      expect(plate.stress_accumulation).to be_within(1e-9).of(0.3)
    end

    it 'accumulates multiple calls' do
      plate.accumulate_stress!(0.2)
      plate.accumulate_stress!(0.1)
      expect(plate.stress_accumulation).to be_within(1e-9).of(0.3)
    end

    it 'treats negative amounts as absolute value' do
      plate.accumulate_stress!(-0.4)
      expect(plate.stress_accumulation).to be_within(1e-9).of(0.4)
    end
  end

  describe '#release_stress!' do
    it 'returns accumulated stress' do
      plate.accumulate_stress!(0.5)
      released = plate.release_stress!
      expect(released).to be_within(1e-9).of(0.5)
    end

    it 'resets stress to 0' do
      plate.accumulate_stress!(0.5)
      plate.release_stress!
      expect(plate.stress_accumulation).to eq(0.0)
    end
  end

  describe '#subducted?' do
    it 'returns false when mass is high' do
      plate.mass = 0.8
      expect(plate.subducted?).to be(false)
    end

    it 'returns true when mass is below SUBDUCTION_RATIO' do
      plate.mass = 0.3
      expect(plate.subducted?).to be(true)
    end

    it 'returns false when mass equals SUBDUCTION_RATIO exactly' do
      plate.mass = Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::Constants::SUBDUCTION_RATIO
      expect(plate.subducted?).to be(false)
    end
  end

  describe '#subduct!' do
    it 'sets state to :subducted' do
      plate.subduct!
      expect(plate.state).to eq(:subducted)
    end
  end

  describe '#dormant!' do
    it 'sets state to :dormant' do
      plate.dormant!
      expect(plate.state).to eq(:dormant)
    end
  end

  describe '#active?' do
    it 'returns true for :active state' do
      expect(plate.active?).to be(true)
    end

    it 'returns false after subducted' do
      plate.subduct!
      expect(plate.active?).to be(false)
    end
  end

  describe '#distance_to' do
    let(:plate_a) { described_class.new(domain: :a, content: 'a', position: { x: 0.0, y: 0.0 }) }
    let(:plate_b) { described_class.new(domain: :b, content: 'b', position: { x: 3.0, y: 4.0 }) }

    it 'calculates Euclidean distance' do
      expect(plate_a.distance_to(plate_b)).to be_within(1e-9).of(5.0)
    end

    it 'returns 0 for same position' do
      p2 = described_class.new(domain: :b, content: 'b', position: { x: 0.0, y: 0.0 })
      expect(plate_a.distance_to(p2)).to eq(0.0)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = plate.to_h
      expect(h).to include(:id, :domain, :content, :mass, :drift_vector, :position,
                           :velocity, :stress_accumulation, :state, :created_at)
    end

    it 'reflects current state values' do
      plate.mass = 0.9
      expect(plate.to_h[:mass]).to eq(0.9)
    end
  end
end
