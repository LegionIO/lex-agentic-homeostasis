# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Grain do
  let(:grain) { described_class.new(grain_type: :attention, domain: 'focus', content: 'test', weight: 0.8) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(grain.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets grain_type as symbol' do
      expect(grain.grain_type).to eq(:attention)
    end

    it 'sets domain as string' do
      expect(grain.domain).to eq('focus')
    end

    it 'sets content' do
      expect(grain.content).to eq('test')
    end

    it 'clamps weight to [0.0, 1.0]' do
      g = described_class.new(grain_type: :focus, weight: 0.5)
      expect(g.weight).to eq(0.5)
    end

    it 'accepts all valid grain_types' do
      Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Constants::GRAIN_TYPES.each do |type|
        expect { described_class.new(grain_type: type) }.not_to raise_error
      end
    end

    it 'raises ArgumentError for unknown grain_type' do
      expect { described_class.new(grain_type: :invalid) }.to raise_error(ArgumentError, /unknown grain_type/)
    end

    it 'raises ArgumentError for weight outside [0, 1]' do
      expect { described_class.new(grain_type: :attention, weight: 1.5) }.to raise_error(ArgumentError, /weight/)
    end

    it 'raises ArgumentError for negative weight' do
      expect { described_class.new(grain_type: :attention, weight: -0.1) }.to raise_error(ArgumentError, /weight/)
    end

    it 'sets created_at as UTC time' do
      expect(grain.created_at).to be_a(Time)
    end

    it 'defaults domain to nil' do
      g = described_class.new(grain_type: :focus)
      expect(g.domain).to be_nil
    end

    it 'defaults content to nil' do
      g = described_class.new(grain_type: :focus)
      expect(g.content).to be_nil
    end

    it 'defaults weight to 1.0' do
      g = described_class.new(grain_type: :focus)
      expect(g.weight).to eq(1.0)
    end

    it 'accepts string grain_type and converts to symbol' do
      g = described_class.new(grain_type: 'attention')
      expect(g.grain_type).to eq(:attention)
    end
  end

  describe '#erode!' do
    it 'reduces weight by rate' do
      grain = described_class.new(grain_type: :attention, weight: 0.8)
      grain.erode!(0.1)
      expect(grain.weight).to be_within(0.001).of(0.7)
    end

    it 'floors at 0.0' do
      grain = described_class.new(grain_type: :attention, weight: 0.05)
      grain.erode!(0.1)
      expect(grain.weight).to eq(0.0)
    end

    it 'returns self for chaining' do
      g = described_class.new(grain_type: :focus, weight: 0.5)
      expect(g.erode!(0.1)).to equal(g)
    end

    it 'uses default rate of 0.01' do
      grain = described_class.new(grain_type: :attention, weight: 0.5)
      grain.erode!
      expect(grain.weight).to be_within(0.001).of(0.49)
    end
  end

  describe '#solidify!' do
    it 'increases weight by rate' do
      grain = described_class.new(grain_type: :attention, weight: 0.5)
      grain.solidify!(0.1)
      expect(grain.weight).to be_within(0.001).of(0.6)
    end

    it 'caps at 1.0' do
      grain = described_class.new(grain_type: :attention, weight: 0.95)
      grain.solidify!(0.1)
      expect(grain.weight).to eq(1.0)
    end

    it 'returns self for chaining' do
      g = described_class.new(grain_type: :focus, weight: 0.5)
      expect(g.solidify!(0.1)).to equal(g)
    end

    it 'uses default rate of 0.01' do
      grain = described_class.new(grain_type: :attention, weight: 0.5)
      grain.solidify!
      expect(grain.weight).to be_within(0.001).of(0.51)
    end
  end

  describe '#dust?' do
    it 'returns true when weight is below 0.05' do
      g = described_class.new(grain_type: :attention, weight: 0.04)
      expect(g.dust?).to be(true)
    end

    it 'returns false when weight is 0.05 or above' do
      g = described_class.new(grain_type: :attention, weight: 0.05)
      expect(g.dust?).to be(false)
    end

    it 'returns false for normal weight grain' do
      expect(grain.dust?).to be(false)
    end

    it 'returns true after full erosion' do
      g = described_class.new(grain_type: :attention, weight: 0.03)
      expect(g.dust?).to be(true)
    end
  end

  describe '#heavy?' do
    it 'returns true when weight is above 0.75' do
      g = described_class.new(grain_type: :attention, weight: 0.8)
      expect(g.heavy?).to be(true)
    end

    it 'returns false when weight is 0.75 or below' do
      g = described_class.new(grain_type: :attention, weight: 0.75)
      expect(g.heavy?).to be(false)
    end

    it 'returns true for the default weight-0.8 grain' do
      expect(grain.heavy?).to be(true)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = grain.to_h
      expect(h.keys).to include(:id, :grain_type, :domain, :content, :weight, :created_at, :dust, :heavy)
    end

    it 'dust key reflects dust? state' do
      g = described_class.new(grain_type: :attention, weight: 0.03)
      expect(g.to_h[:dust]).to be(true)
    end

    it 'heavy key reflects heavy? state' do
      g = described_class.new(grain_type: :attention, weight: 0.9)
      expect(g.to_h[:heavy]).to be(true)
    end
  end
end
