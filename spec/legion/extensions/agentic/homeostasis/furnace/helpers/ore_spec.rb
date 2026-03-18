# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Ore do
  let(:ore) { described_class.new(ore_type: :experience, domain: 'cognition', content: 'test observation') }

  describe '#initialize' do
    it 'creates an ore with required attributes' do
      expect(ore.ore_type).to eq(:experience)
      expect(ore.domain).to eq('cognition')
      expect(ore.content).to eq('test observation')
    end

    it 'assigns a uuid ore_id' do
      expect(ore.ore_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'defaults purity to 0.5' do
      expect(ore.purity).to eq(0.5)
    end

    it 'defaults impurity to complement of purity' do
      expect(ore.impurity).to be_within(0.001).of(0.5)
    end

    it 'accepts custom purity' do
      o = described_class.new(ore_type: :data, domain: 'test', content: 'x', purity: 0.8)
      expect(o.purity).to eq(0.8)
    end

    it 'accepts custom impurity' do
      o = described_class.new(ore_type: :data, domain: 'test', content: 'x', purity: 0.8, impurity: 0.1)
      expect(o.impurity).to eq(0.1)
    end

    it 'clamps purity above 1.0' do
      o = described_class.new(ore_type: :data, domain: 'test', content: 'x', purity: 1.5)
      expect(o.purity).to eq(1.0)
    end

    it 'clamps purity below 0.0' do
      o = described_class.new(ore_type: :data, domain: 'test', content: 'x', purity: -0.3)
      expect(o.purity).to eq(0.0)
    end

    it 'raises ArgumentError for unknown ore_type' do
      expect { described_class.new(ore_type: :unknown, domain: 'x', content: 'y') }.to raise_error(ArgumentError)
    end

    it 'accepts all valid ore types' do
      Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::ORE_TYPES.each do |t|
        expect { described_class.new(ore_type: t, domain: 'x', content: 'y') }.not_to raise_error
      end
    end

    it 'accepts a custom ore_id' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', ore_id: 'custom-id')
      expect(o.ore_id).to eq('custom-id')
    end

    it 'sets created_at' do
      expect(ore.created_at).to be_a(Time)
    end
  end

  describe '#refine!' do
    it 'increases purity by HEAT_RATE' do
      before = ore.purity
      ore.refine!
      expect(ore.purity).to be_within(0.001).of(before + 0.1)
    end

    it 'decreases impurity by HEAT_RATE' do
      before = ore.impurity
      ore.refine!
      expect(ore.impurity).to be_within(0.001).of(before - 0.1)
    end

    it 'clamps purity at 1.0' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.95)
      o.refine!
      expect(o.purity).to eq(1.0)
    end

    it 'accepts custom rate' do
      before = ore.purity
      ore.refine!(0.2)
      expect(ore.purity).to be_within(0.001).of(before + 0.2)
    end

    it 'returns self for chaining' do
      expect(ore.refine!).to eq(ore)
    end
  end

  describe '#contaminate!' do
    it 'decreases purity by COOL_RATE' do
      before = ore.purity
      ore.contaminate!
      expect(ore.purity).to be_within(0.001).of(before - 0.05)
    end

    it 'increases impurity by COOL_RATE' do
      before = ore.impurity
      ore.contaminate!
      expect(ore.impurity).to be_within(0.001).of(before + 0.05)
    end

    it 'clamps purity at 0.0' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.02)
      o.contaminate!
      expect(o.purity).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(ore.contaminate!).to eq(ore)
    end
  end

  describe '#pure?' do
    it 'returns true when purity >= 0.8' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.85)
      expect(o.pure?).to be true
    end

    it 'returns false when purity < 0.8' do
      expect(ore.pure?).to be false
    end

    it 'returns true at exactly 0.8' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.8)
      expect(o.pure?).to be true
    end
  end

  describe '#crude?' do
    it 'returns true when purity < 0.3' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.2)
      expect(o.crude?).to be true
    end

    it 'returns false when purity >= 0.3' do
      expect(ore.crude?).to be false
    end
  end

  describe '#purity_label' do
    it 'returns :refined for high purity' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.9)
      expect(o.purity_label).to eq(:refined)
    end

    it 'returns :impure for very low purity' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.1)
      expect(o.purity_label).to eq(:impure)
    end

    it 'returns :raw for middle purity' do
      o = described_class.new(ore_type: :data, domain: 'x', content: 'y', purity: 0.5)
      expect(o.purity_label).to eq(:raw)
    end
  end

  describe '#to_h' do
    it 'includes ore_id, ore_type, domain, content' do
      h = ore.to_h
      expect(h[:ore_id]).to eq(ore.ore_id)
      expect(h[:ore_type]).to eq(:experience)
      expect(h[:domain]).to eq('cognition')
      expect(h[:content]).to eq('test observation')
    end

    it 'includes purity and impurity' do
      h = ore.to_h
      expect(h[:purity]).to be_a(Float)
      expect(h[:impurity]).to be_a(Float)
    end

    it 'includes pure and crude boolean flags' do
      h = ore.to_h
      expect(h).to have_key(:pure)
      expect(h).to have_key(:crude)
    end

    it 'includes label' do
      expect(ore.to_h[:label]).to be_a(Symbol)
    end

    it 'includes created_at' do
      expect(ore.to_h[:created_at]).to be_a(Time)
    end
  end
end
