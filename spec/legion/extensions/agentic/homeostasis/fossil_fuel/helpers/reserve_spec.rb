# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::Reserve do
  subject(:reserve) do
    described_class.new(fuel_type: :coal, domain: :energy, content: 'anthracite deposit')
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(reserve.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets fuel_type as symbol' do
      expect(reserve.fuel_type).to eq(:coal)
    end

    it 'sets domain as symbol' do
      expect(reserve.domain).to eq(:energy)
    end

    it 'stores content as string' do
      expect(reserve.content).to eq('anthracite deposit')
    end

    it 'defaults volume to 0.8' do
      expect(reserve.volume).to eq(0.8)
    end

    it 'defaults quality to 0.5' do
      expect(reserve.quality).to eq(0.5)
    end

    it 'accepts custom volume' do
      r = described_class.new(fuel_type: :oil, domain: :test, content: 'x', volume: 0.3)
      expect(r.volume).to eq(0.3)
    end

    it 'accepts custom quality' do
      r = described_class.new(fuel_type: :gas, domain: :test, content: 'x', quality: 0.9)
      expect(r.quality).to eq(0.9)
    end

    it 'clamps volume to 0..1' do
      r = described_class.new(fuel_type: :peat, domain: :test, content: 'x', volume: 5.0)
      expect(r.volume).to eq(1.0)
    end

    it 'clamps quality to 0..1' do
      r = described_class.new(fuel_type: :shale, domain: :test, content: 'x', quality: -1.0)
      expect(r.quality).to eq(0.0)
    end

    it 'sets discovered_at' do
      expect(reserve.discovered_at).to be_a(Time)
    end

    it 'raises on unknown fuel type' do
      expect do
        described_class.new(fuel_type: :plutonium, domain: :test, content: 'x')
      end.to raise_error(ArgumentError, /unknown fuel type/)
    end

    it 'accepts string fuel type by converting to symbol' do
      r = described_class.new(fuel_type: 'oil', domain: :test, content: 'x')
      expect(r.fuel_type).to eq(:oil)
    end
  end

  describe '#extract!' do
    it 'reduces volume by the default rate' do
      initial = reserve.volume
      reserve.extract!
      expect(reserve.volume).to eq((initial - 0.05).round(10))
    end

    it 'returns the extracted amount' do
      expect(reserve.extract!).to eq(0.05)
    end

    it 'accepts a custom rate' do
      amount = reserve.extract!(rate: 0.3)
      expect(amount).to eq(0.3)
    end

    it 'does not extract more than available volume' do
      reserve.volume = 0.02
      amount = reserve.extract!(rate: 0.1)
      expect(amount).to eq(0.02)
      expect(reserve.volume).to eq(0.0)
    end

    it 'clamps volume at 0' do
      20.times { reserve.extract! }
      expect(reserve.volume).to be >= 0.0
    end
  end

  describe '#depleted?' do
    it 'returns false when volume is above threshold' do
      expect(reserve).not_to be_depleted
    end

    it 'returns true when volume is below 0.01' do
      reserve.volume = 0.005
      expect(reserve).to be_depleted
    end
  end

  describe '#scarce?' do
    it 'returns false at default volume' do
      expect(reserve).not_to be_scarce
    end

    it 'returns true when volume is below depletion warning' do
      reserve.volume = 0.15
      expect(reserve).to be_scarce
    end
  end

  describe '#abundant?' do
    it 'returns true at default volume' do
      expect(reserve).to be_abundant
    end

    it 'returns false when volume drops below 0.8' do
      reserve.volume = 0.5
      expect(reserve).not_to be_abundant
    end
  end

  describe '#reserve_label' do
    it 'returns :abundant for default volume' do
      expect(reserve.reserve_label).to eq(:abundant)
    end

    it 'returns :critical when nearly depleted' do
      reserve.volume = 0.05
      expect(reserve.reserve_label).to eq(:critical)
    end
  end

  describe '#to_h' do
    subject(:hash) { reserve.to_h }

    it 'includes all expected keys' do
      expected_keys = %i[id fuel_type domain content volume reserve_label
                         quality depleted scarce abundant discovered_at]
      expect(hash.keys).to match_array(expected_keys)
    end

    it 'includes the correct fuel_type' do
      expect(hash[:fuel_type]).to eq(:coal)
    end

    it 'includes boolean flags' do
      expect(hash[:depleted]).to be false
      expect(hash[:abundant]).to be true
    end
  end
end
