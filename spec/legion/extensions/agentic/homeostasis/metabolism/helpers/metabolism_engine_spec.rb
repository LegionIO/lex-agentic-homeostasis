# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Metabolism::Helpers::MetabolismEngine do
  subject(:engine) { described_class.new }

  let(:reserve) { engine.create_reserve }
  let(:reserve_id) { reserve.id }

  describe '#create_reserve' do
    it 'returns an EnergyReserve' do
      expect(reserve).to be_a(Legion::Extensions::Agentic::Homeostasis::Metabolism::Helpers::EnergyReserve)
    end

    it 'stores the reserve internally' do
      engine.create_reserve
      expect(engine.all_reserves.size).to be >= 1
    end

    it 'creates reserves with unique ids' do
      r1 = engine.create_reserve
      r2 = engine.create_reserve
      expect(r1.id).not_to eq(r2.id)
    end

    it 'accepts custom max_energy' do
      r = engine.create_reserve(max_energy: 500.0)
      expect(r.max_energy).to eq(500.0)
    end

    it 'accepts custom efficiency' do
      r = engine.create_reserve(efficiency: 0.7)
      expect(r.efficiency).to eq(0.7)
    end
  end

  describe '#spend_energy' do
    it 'returns a hash with success key' do
      # call via runner pattern — test the engine directly here
      result = engine.spend_energy(reserve_id: reserve_id, operation_type: :perception)
      expect(result).to include(:reserve_id, :operation_type, :base_cost, :actual_spent, :current_energy, :state)
    end

    it 'applies perception cost of 5.0' do
      result = engine.spend_energy(reserve_id: reserve_id, operation_type: :perception)
      expect(result[:base_cost]).to eq(5.0)
    end

    it 'applies creativity cost of 20.0' do
      result = engine.spend_energy(reserve_id: reserve_id, operation_type: :creativity)
      expect(result[:base_cost]).to eq(20.0)
    end

    it 'raises ArgumentError for unknown operation type' do
      expect { engine.spend_energy(reserve_id: reserve_id, operation_type: :unknown) }
        .to raise_error(ArgumentError, /Unknown operation type/)
    end

    it 'raises ArgumentError for unknown reserve_id' do
      expect { engine.spend_energy(reserve_id: 'fake-id', operation_type: :perception) }
        .to raise_error(ArgumentError, /Unknown reserve/)
    end

    it 'records efficiency history' do
      engine.spend_energy(reserve_id: reserve_id, operation_type: :reasoning)
      expect(engine.efficiency_history).not_to be_empty
    end
  end

  describe '#recover' do
    before { engine.spend_energy(reserve_id: reserve_id, operation_type: :creativity) }

    it 'returns a hash with energy_gained' do
      result = engine.recover(reserve_id: reserve_id, duration: 1.0)
      expect(result).to include(:reserve_id, :duration, :energy_gained, :current_energy, :state)
    end

    it 'recovers energy proportional to duration' do
      r1 = engine.recover(reserve_id: reserve_id, duration: 1.0)
      r2 = engine.recover(reserve_id: reserve_id, duration: 2.0)
      expect(r2[:energy_gained]).to be > r1[:energy_gained]
    end

    it 'records efficiency history' do
      engine.recover(reserve_id: reserve_id)
      expect(engine.efficiency_history).not_to be_empty
    end

    it 'raises ArgumentError for unknown reserve_id' do
      expect { engine.recover(reserve_id: 'fake-id') }
        .to raise_error(ArgumentError, /Unknown reserve/)
    end
  end

  describe '#catabolize' do
    it 'returns a hash including energy_gained and reserve_id' do
      result = engine.catabolize(reserve_id: reserve_id, complexity: 1.0)
      expect(result).to include(:energy_gained, :current_energy, :state, :reserve_id)
    end

    it 'raises ArgumentError for unknown reserve' do
      expect { engine.catabolize(reserve_id: 'nope', complexity: 1.0) }
        .to raise_error(ArgumentError, /Unknown reserve/)
    end
  end

  describe '#anabolize' do
    it 'returns a hash including structure_value and reserve_id' do
      result = engine.anabolize(reserve_id: reserve_id, energy_cost: 10.0)
      expect(result).to include(:energy_spent, :structure_value, :current_energy, :state, :reserve_id)
    end

    it 'raises ArgumentError for unknown reserve' do
      expect { engine.anabolize(reserve_id: 'nope', energy_cost: 10.0) }
        .to raise_error(ArgumentError, /Unknown reserve/)
    end
  end

  describe '#run_cycle' do
    it 'returns a hash with cycle_count and reserve_state' do
      result = engine.run_cycle(reserve_id: reserve_id, operations: %i[perception reasoning])
      expect(result).to include(:cycle_count, :reserve_state, :reserve_energy, :energy_spent_this_cycle)
    end

    it 'counts all operations plus resting rate' do
      result = engine.run_cycle(reserve_id: reserve_id, operations: %i[perception reasoning])
      expect(result[:cycle_count]).to eq(3)
    end

    it 'handles empty operations list' do
      result = engine.run_cycle(reserve_id: reserve_id, operations: [])
      expect(result[:cycle_count]).to eq(1)
    end

    it 'raises ArgumentError for unknown reserve' do
      expect { engine.run_cycle(reserve_id: 'bad', operations: []) }
        .to raise_error(ArgumentError, /Unknown reserve/)
    end
  end

  describe '#metabolic_report' do
    it 'returns reserve and efficiency_history keys' do
      result = engine.metabolic_report(reserve_id: reserve_id)
      expect(result).to include(:reserve, :efficiency_history)
    end

    it 'raises ArgumentError for unknown reserve' do
      expect { engine.metabolic_report(reserve_id: 'bad') }
        .to raise_error(ArgumentError, /Unknown reserve/)
    end
  end

  describe '#all_reserves' do
    it 'returns empty hash when no reserves exist' do
      fresh_engine = described_class.new
      expect(fresh_engine.all_reserves).to eq({})
    end

    it 'returns all created reserves as hashes' do
      fresh_engine = described_class.new
      fresh_engine.create_reserve
      fresh_engine.create_reserve
      expect(fresh_engine.all_reserves.size).to eq(2)
    end
  end

  describe '#efficiency_history' do
    it 'returns empty array initially' do
      fresh_engine = described_class.new
      expect(fresh_engine.efficiency_history).to eq([])
    end

    it 'grows after spending' do
      engine.spend_energy(reserve_id: reserve_id, operation_type: :decision)
      expect(engine.efficiency_history.size).to be >= 1
    end

    it 'caps at MAX_EFFICIENCY_HISTORY entries' do
      210.times { engine.spend_energy(reserve_id: reserve_id, operation_type: :perception) }
      expect(engine.efficiency_history.size).to be <= 200
    end
  end
end
