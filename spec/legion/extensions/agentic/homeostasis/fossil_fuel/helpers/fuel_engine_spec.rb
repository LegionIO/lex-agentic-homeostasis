# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::FuelEngine do
  subject(:engine) { described_class.new }

  let(:default_attrs) { { fuel_type: :coal, domain: :energy, content: 'test deposit' } }

  describe '#create_reserve' do
    it 'creates a reserve and returns it' do
      r = engine.create_reserve(**default_attrs)
      expect(r).to be_a(Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::Reserve)
    end

    it 'stores the reserve internally' do
      engine.create_reserve(**default_attrs)
      expect(engine.all_reserves.size).to eq(1)
    end

    it 'accepts volume and quality' do
      r = engine.create_reserve(**default_attrs, volume: 0.6, quality: 0.9)
      expect(r.volume).to eq(0.6)
      expect(r.quality).to eq(0.9)
    end

    it 'raises when reserve limit reached' do
      stub_const('Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::Constants::MAX_RESERVES', 2)
      engine.create_reserve(**default_attrs)
      engine.create_reserve(**default_attrs, fuel_type: :oil)
      expect do
        engine.create_reserve(**default_attrs, fuel_type: :gas)
      end.to raise_error(ArgumentError, /reserve limit/)
    end
  end

  describe '#extract' do
    it 'extracts from a reserve and returns result' do
      r = engine.create_reserve(**default_attrs)
      result = engine.extract(reserve_id: r.id)
      expect(result[:reserve]).to eq(r)
      expect(result[:extracted]).to eq(0.05)
    end

    it 'accepts a custom rate' do
      r = engine.create_reserve(**default_attrs)
      result = engine.extract(reserve_id: r.id, rate: 0.2)
      expect(result[:extracted]).to eq(0.2)
    end

    it 'raises for unknown reserve' do
      expect do
        engine.extract(reserve_id: 'nonexistent')
      end.to raise_error(ArgumentError, /reserve not found/)
    end
  end

  describe '#combust' do
    it 'extracts fuel and creates a combustion' do
      r = engine.create_reserve(**default_attrs, volume: 0.5)
      result = engine.combust(reserve_id: r.id, amount: 0.1)
      expect(result[:combustion]).to be_a(Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::Combustion)
      expect(result[:reserve]).to eq(r)
    end

    it 'uses default extraction rate when no amount given' do
      r = engine.create_reserve(**default_attrs)
      result = engine.combust(reserve_id: r.id)
      expect(result[:combustion].fuel_amount).to eq(0.05)
    end

    it 'accepts a grade parameter' do
      r = engine.create_reserve(**default_attrs)
      result = engine.combust(reserve_id: r.id, grade: :premium)
      expect(result[:combustion].grade).to eq(:premium)
    end

    it 'raises when reserve is depleted' do
      r = engine.create_reserve(**default_attrs, volume: 0.0005)
      expect do
        engine.combust(reserve_id: r.id)
      end.to raise_error(ArgumentError, /reserve depleted/)
    end

    it 'stores the combustion' do
      r = engine.create_reserve(**default_attrs)
      engine.combust(reserve_id: r.id)
      expect(engine.all_combustions.size).to eq(1)
    end
  end

  describe '#total_energy_released' do
    it 'returns 0 with no combustions' do
      expect(engine.total_energy_released).to eq(0.0)
    end

    it 'sums energy from all combustions' do
      r = engine.create_reserve(**default_attrs, volume: 0.9)
      engine.combust(reserve_id: r.id, amount: 0.1)
      engine.combust(reserve_id: r.id, amount: 0.1)
      expect(engine.total_energy_released).to be > 0.0
    end
  end

  describe '#reserves_by_type' do
    it 'returns counts for all fuel types' do
      counts = engine.reserves_by_type
      expect(counts.keys).to match_array(%i[coal oil gas peat shale])
      expect(counts.values).to all(eq(0))
    end

    it 'counts reserves by type' do
      engine.create_reserve(**default_attrs)
      engine.create_reserve(fuel_type: :oil, domain: :test, content: 'x')
      engine.create_reserve(fuel_type: :oil, domain: :test, content: 'y')
      counts = engine.reserves_by_type
      expect(counts[:coal]).to eq(1)
      expect(counts[:oil]).to eq(2)
    end
  end

  describe '#scarce_reserves' do
    it 'returns empty when no reserves are scarce' do
      engine.create_reserve(**default_attrs)
      expect(engine.scarce_reserves).to be_empty
    end

    it 'returns reserves below depletion warning' do
      r = engine.create_reserve(**default_attrs, volume: 0.1)
      expect(engine.scarce_reserves).to include(r)
    end
  end

  describe '#depleted_reserves' do
    it 'returns empty initially' do
      engine.create_reserve(**default_attrs)
      expect(engine.depleted_reserves).to be_empty
    end

    it 'returns depleted reserves' do
      r = engine.create_reserve(**default_attrs, volume: 0.005)
      expect(engine.depleted_reserves).to include(r)
    end
  end

  describe '#richest' do
    it 'returns reserves sorted by volume descending' do
      r1 = engine.create_reserve(**default_attrs, volume: 0.3)
      r2 = engine.create_reserve(fuel_type: :oil, domain: :test, content: 'x', volume: 0.9)
      r3 = engine.create_reserve(fuel_type: :gas, domain: :test, content: 'y', volume: 0.6)
      expect(engine.richest(limit: 3)).to eq([r2, r3, r1])
    end

    it 'defaults to limit of 5' do
      7.times { |i| engine.create_reserve(fuel_type: :coal, domain: :test, content: "r#{i}") }
      expect(engine.richest.size).to eq(5)
    end
  end

  describe '#fuel_report' do
    it 'returns a comprehensive hash' do
      engine.create_reserve(**default_attrs)
      report = engine.fuel_report
      expect(report).to include(
        :total_reserves, :total_combustions, :total_energy,
        :by_type, :depleted_count, :scarce_count, :avg_volume, :avg_quality
      )
    end

    it 'has correct counts' do
      engine.create_reserve(**default_attrs)
      r2 = engine.create_reserve(fuel_type: :oil, domain: :test, content: 'x')
      engine.combust(reserve_id: r2.id)
      report = engine.fuel_report
      expect(report[:total_reserves]).to eq(2)
      expect(report[:total_combustions]).to eq(1)
    end

    it 'calculates averages correctly' do
      engine.create_reserve(**default_attrs, volume: 0.4, quality: 0.6)
      engine.create_reserve(fuel_type: :oil, domain: :test, content: 'x', volume: 0.8, quality: 0.4)
      report = engine.fuel_report
      expect(report[:avg_volume]).to eq(0.6)
      expect(report[:avg_quality]).to eq(0.5)
    end

    it 'handles empty engine' do
      report = engine.fuel_report
      expect(report[:total_reserves]).to eq(0)
      expect(report[:avg_volume]).to eq(0.0)
    end
  end

  describe '#all_reserves' do
    it 'returns all stored reserves' do
      engine.create_reserve(**default_attrs)
      engine.create_reserve(fuel_type: :gas, domain: :test, content: 'x')
      expect(engine.all_reserves.size).to eq(2)
    end
  end

  describe '#all_combustions' do
    it 'returns all stored combustions' do
      r = engine.create_reserve(**default_attrs)
      engine.combust(reserve_id: r.id)
      expect(engine.all_combustions.size).to eq(1)
    end
  end
end
