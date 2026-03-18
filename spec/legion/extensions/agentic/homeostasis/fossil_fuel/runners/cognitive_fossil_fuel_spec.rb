# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FossilFuel::Runners::CognitiveFossilFuel do
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  let(:engine) { Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::FuelEngine.new }

  describe '#create_reserve' do
    it 'returns success with reserve hash' do
      result = runner.create_reserve(fuel_type: :coal, domain: :energy,
                                     content: 'test', engine: engine)
      expect(result[:success]).to be true
      expect(result[:reserve]).to be_a(Hash)
      expect(result[:reserve][:fuel_type]).to eq(:coal)
    end

    it 'returns failure for invalid fuel type' do
      result = runner.create_reserve(fuel_type: :uranium, domain: :test,
                                     content: 'x', engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/unknown fuel type/)
    end

    it 'passes volume and quality through' do
      result = runner.create_reserve(fuel_type: :oil, domain: :test, content: 'x',
                                     volume: 0.6, quality: 0.9, engine: engine)
      expect(result[:reserve][:volume]).to eq(0.6)
      expect(result[:reserve][:quality]).to eq(0.9)
    end
  end

  describe '#extract' do
    let(:reserve_id) do
      r = engine.create_reserve(fuel_type: :gas, domain: :test, content: 'deposit')
      r.id
    end

    it 'returns success with reserve and extracted amount' do
      result = runner.extract(reserve_id: reserve_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:extracted]).to eq(0.05)
      expect(result[:reserve]).to be_a(Hash)
    end

    it 'accepts a custom rate' do
      result = runner.extract(reserve_id: reserve_id, rate: 0.2, engine: engine)
      expect(result[:extracted]).to eq(0.2)
    end

    it 'returns failure for unknown reserve' do
      result = runner.extract(reserve_id: 'bad-id', engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/reserve not found/)
    end
  end

  describe '#combust' do
    let(:reserve_id) do
      r = engine.create_reserve(fuel_type: :oil, domain: :test, content: 'crude')
      r.id
    end

    it 'returns success with combustion and reserve' do
      result = runner.combust(reserve_id: reserve_id, engine: engine)
      expect(result[:success]).to be true
      expect(result[:combustion]).to be_a(Hash)
      expect(result[:reserve]).to be_a(Hash)
    end

    it 'accepts amount and grade' do
      result = runner.combust(reserve_id: reserve_id, amount: 0.1,
                              grade: :premium, engine: engine)
      expect(result[:combustion][:grade]).to eq(:premium)
    end

    it 'returns failure for depleted reserve' do
      r = engine.create_reserve(fuel_type: :peat, domain: :test, content: 'x', volume: 0.0005)
      result = runner.combust(reserve_id: r.id, engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/reserve depleted/)
    end
  end

  describe '#list_reserves' do
    before do
      engine.create_reserve(fuel_type: :coal, domain: :test, content: 'a')
      engine.create_reserve(fuel_type: :oil, domain: :test, content: 'b')
      engine.create_reserve(fuel_type: :coal, domain: :test, content: 'c')
    end

    it 'returns all reserves' do
      result = runner.list_reserves(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(3)
    end

    it 'filters by fuel_type' do
      result = runner.list_reserves(engine: engine, fuel_type: :coal)
      expect(result[:count]).to eq(2)
      expect(result[:reserves].map { |r| r[:fuel_type] }).to all(eq(:coal))
    end

    it 'returns empty when no matches' do
      result = runner.list_reserves(engine: engine, fuel_type: :shale)
      expect(result[:count]).to eq(0)
    end
  end

  describe '#fuel_status' do
    it 'returns a report' do
      result = runner.fuel_status(engine: engine)
      expect(result[:success]).to be true
      expect(result[:report]).to be_a(Hash)
      expect(result[:report]).to include(:total_reserves, :total_energy)
    end
  end
end
