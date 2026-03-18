# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weather::Helpers::Front do
  subject(:front) { described_class.new(front_type: :warm, domain: 'planning') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(front.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets front_type' do
      expect(front.front_type).to eq(:warm)
    end

    it 'sets domain as string' do
      expect(front.domain).to eq('planning')
    end

    it 'defaults pressure to 0.5' do
      expect(front.pressure).to eq(0.5)
    end

    it 'defaults temperature to 0.5' do
      expect(front.temperature).to eq(0.5)
    end

    it 'defaults humidity to 0.5' do
      expect(front.humidity).to eq(0.5)
    end

    it 'clamps pressure above 1.0' do
      f = described_class.new(front_type: :cold, domain: 'x', pressure: 1.5)
      expect(f.pressure).to eq(1.0)
    end

    it 'clamps pressure below 0.0' do
      f = described_class.new(front_type: :cold, domain: 'x', pressure: -0.1)
      expect(f.pressure).to eq(0.0)
    end

    it 'clamps temperature to [0, 1]' do
      f = described_class.new(front_type: :cold, domain: 'x', temperature: 2.0)
      expect(f.temperature).to eq(1.0)
    end

    it 'clamps humidity to [0, 1]' do
      f = described_class.new(front_type: :cold, domain: 'x', humidity: -1.0)
      expect(f.humidity).to eq(0.0)
    end

    it 'sets created_at' do
      expect(front.created_at).to be_a(Time)
    end

    it 'raises ArgumentError for unknown front_type' do
      expect { described_class.new(front_type: :plasma, domain: 'x') }.to raise_error(ArgumentError, /unknown front_type/)
    end

    it 'accepts all valid front types' do
      %i[warm cold occluded stationary].each do |type|
        expect { described_class.new(front_type: type, domain: 'x') }.not_to raise_error
      end
    end
  end

  describe '#advance!' do
    it 'increases pressure by default rate' do
      initial = front.pressure
      front.advance!
      expect(front.pressure).to be > initial
    end

    it 'accepts a custom rate' do
      front.advance!(0.2)
      expect(front.pressure).to be_within(0.001).of(0.7)
    end

    it 'clamps at 1.0' do
      f = described_class.new(front_type: :warm, domain: 'x', pressure: 0.99)
      f.advance!(0.5)
      expect(f.pressure).to eq(1.0)
    end
  end

  describe '#retreat!' do
    it 'decreases pressure by default rate' do
      initial = front.pressure
      front.retreat!
      expect(front.pressure).to be < initial
    end

    it 'accepts a custom rate' do
      front.retreat!(0.2)
      expect(front.pressure).to be_within(0.001).of(0.3)
    end

    it 'clamps at 0.0' do
      f = described_class.new(front_type: :warm, domain: 'x', pressure: 0.01)
      f.retreat!(0.5)
      expect(f.pressure).to eq(0.0)
    end
  end

  describe '#high_pressure?' do
    it 'returns true when pressure >= 0.65' do
      f = described_class.new(front_type: :warm, domain: 'x', pressure: 0.8)
      expect(f.high_pressure?).to be true
    end

    it 'returns false when pressure < 0.65' do
      f = described_class.new(front_type: :warm, domain: 'x', pressure: 0.5)
      expect(f.high_pressure?).to be false
    end
  end

  describe '#low_pressure?' do
    it 'returns true when pressure <= 0.35' do
      f = described_class.new(front_type: :cold, domain: 'x', pressure: 0.2)
      expect(f.low_pressure?).to be true
    end

    it 'returns false when pressure > 0.35' do
      f = described_class.new(front_type: :cold, domain: 'x', pressure: 0.5)
      expect(f.low_pressure?).to be false
    end
  end

  describe '#severity_label' do
    it 'returns calm for 0.0 pressure' do
      f = described_class.new(front_type: :warm, domain: 'x', pressure: 0.0)
      expect(f.severity_label).to eq('calm')
    end

    it 'returns catastrophic for 1.0 pressure' do
      f = described_class.new(front_type: :warm, domain: 'x', pressure: 1.0)
      expect(f.severity_label).to eq('catastrophic')
    end

    it 'returns moderate for 0.6 pressure' do
      f = described_class.new(front_type: :warm, domain: 'x', pressure: 0.6)
      expect(f.severity_label).to eq('moderate')
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = front.to_h
      expect(h.keys).to include(:id, :front_type, :domain, :pressure, :temperature,
                                :humidity, :high_pressure, :low_pressure, :severity, :created_at)
    end

    it 'rounds pressure to 10 decimal places' do
      expect(front.to_h[:pressure]).to eq(0.5.round(10))
    end

    it 'includes created_at as ISO8601 string' do
      expect(front.to_h[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end
end
