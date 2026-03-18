# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Metabolism::Helpers::EnergyReserve do
  subject(:reserve) { described_class.new }

  describe '#initialize' do
    it 'starts at full energy' do
      expect(reserve.current_energy).to eq(1000.0)
    end

    it 'sets max_energy to MAX_ENERGY by default' do
      expect(reserve.max_energy).to eq(1000.0)
    end

    it 'sets default metabolic_rate' do
      expect(reserve.metabolic_rate).to eq(0.5)
    end

    it 'sets default efficiency to 1.0' do
      expect(reserve.efficiency).to eq(1.0)
    end

    it 'generates a UUID id' do
      expect(reserve.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets created_at' do
      expect(reserve.created_at).to be_a(Time)
    end

    it 'accepts custom max_energy' do
      r = described_class.new(max_energy: 500.0)
      expect(r.max_energy).to eq(500.0)
      expect(r.current_energy).to eq(500.0)
    end

    it 'accepts custom metabolic_rate' do
      r = described_class.new(metabolic_rate: 1.0)
      expect(r.metabolic_rate).to eq(1.0)
    end

    it 'accepts custom efficiency' do
      r = described_class.new(efficiency: 0.8)
      expect(r.efficiency).to eq(0.8)
    end

    it 'clamps efficiency above 1.0' do
      r = described_class.new(efficiency: 1.5)
      expect(r.efficiency).to eq(1.0)
    end

    it 'clamps efficiency below 0.0' do
      r = described_class.new(efficiency: -0.5)
      expect(r.efficiency).to eq(0.0)
    end
  end

  describe '#energy_ratio' do
    it 'returns 1.0 when full' do
      expect(reserve.energy_ratio).to eq(1.0)
    end

    it 'returns 0.5 when half depleted' do
      r = described_class.new(max_energy: 100.0)
      r.spend!(50.0)
      expect(r.energy_ratio).to be_within(0.1).of(0.5)
    end
  end

  describe '#state' do
    it 'returns :optimal when at full energy' do
      expect(reserve.state).to eq(:optimal)
    end

    it 'returns :depleted when near empty' do
      r = described_class.new(max_energy: 100.0)
      r.spend!(90.0)
      expect(r.state).to eq(:depleted)
    end
  end

  describe '#depleted?' do
    it 'returns false when at full energy' do
      expect(reserve.depleted?).to be false
    end

    it 'returns true when depleted' do
      r = described_class.new(max_energy: 100.0)
      r.spend!(95.0)
      expect(r.depleted?).to be true
    end
  end

  describe '#spend!' do
    let(:r) { described_class.new(max_energy: 100.0) }

    it 'reduces energy' do
      r.spend!(10.0)
      expect(r.current_energy).to be < 100.0
    end

    it 'returns the actual amount spent' do
      spent = r.spend!(10.0)
      expect(spent).to be > 0.0
    end

    it 'floors energy at 0.0' do
      r.spend!(999.0)
      expect(r.current_energy).to eq(0.0)
    end

    it 'decays efficiency after spending' do
      initial_efficiency = r.efficiency
      r.spend!(10.0)
      expect(r.efficiency).to be < initial_efficiency
    end

    it 'applies efficiency modifier to effective cost' do
      r_half = described_class.new(max_energy: 1000.0, efficiency: 0.5)
      spent = r_half.spend!(10.0)
      expect(spent).to be_within(0.01).of(20.0)
    end
  end

  describe '#recover!' do
    let(:r) { described_class.new(max_energy: 100.0) }

    before { r.spend!(30.0) }

    it 'increases energy' do
      before = r.current_energy
      r.recover!(10.0)
      expect(r.current_energy).to be > before
    end

    it 'returns the actual amount recovered' do
      gained = r.recover!(10.0)
      expect(gained).to be > 0.0
    end

    it 'caps energy at max_energy' do
      r.recover!(999.0)
      expect(r.current_energy).to eq(100.0)
    end

    it 'restores some efficiency' do
      r.spend!(10.0)
      efficiency_after_spend = r.efficiency
      r.recover!(5.0)
      expect(r.efficiency).to be > efficiency_after_spend
    end
  end

  describe '#catabolize!' do
    it 'returns a hash with energy_gained' do
      result = reserve.catabolize!(complexity: 1.0)
      expect(result).to include(:energy_gained, :current_energy, :state)
    end

    it 'does not exceed max_energy' do
      reserve.catabolize!(complexity: 999.0)
      expect(reserve.current_energy).to eq(reserve.max_energy)
    end

    it 'gains more energy for higher complexity' do
      r1 = described_class.new(max_energy: 100.0)
      r2 = described_class.new(max_energy: 100.0)
      r1.spend!(90.0)
      r2.spend!(90.0)
      result_low  = r1.catabolize!(complexity: 1.0)
      result_high = r2.catabolize!(complexity: 5.0)
      expect(result_high[:energy_gained]).to be > result_low[:energy_gained]
    end
  end

  describe '#anabolize!' do
    it 'returns a hash with structure_value and energy_spent' do
      result = reserve.anabolize!(energy_cost: 10.0)
      expect(result).to include(:energy_spent, :structure_value, :current_energy, :state)
    end

    it 'reduces energy by the specified cost' do
      initial = reserve.current_energy
      reserve.anabolize!(energy_cost: 10.0)
      expect(reserve.current_energy).to be < initial
    end

    it 'raises ArgumentError when insufficient energy' do
      r = described_class.new(max_energy: 5.0)
      r.spend!(4.9)
      expect { r.anabolize!(energy_cost: 5.0) }.to raise_error(ArgumentError, /insufficient energy/)
    end

    it 'scales structure_value by efficiency' do
      r_high = described_class.new(efficiency: 1.0, max_energy: 1000.0)
      r_low  = described_class.new(efficiency: 0.5, max_energy: 1000.0)
      high_result = r_high.anabolize!(energy_cost: 10.0)
      low_result  = r_low.anabolize!(energy_cost: 10.0)
      expect(high_result[:structure_value]).to be > low_result[:structure_value]
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = reserve.to_h
      expect(h.keys).to include(:id, :current_energy, :max_energy, :metabolic_rate,
                                :efficiency, :energy_ratio, :state, :depleted, :created_at)
    end

    it 'reflects current state' do
      r = described_class.new(max_energy: 100.0)
      r.spend!(30.0)
      h = r.to_h
      expect(h[:current_energy]).to be < 100.0
    end
  end
end
