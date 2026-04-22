# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/metabolism/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Metabolism::Runners::CognitiveMetabolism do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Metabolism::Client.new }

  describe '#create_reserve' do
    it 'returns success: true' do
      result = client.create_reserve
      expect(result[:success]).to be true
    end

    it 'returns a reserve hash' do
      result = client.create_reserve
      expect(result[:reserve]).to be_a(Hash)
    end

    it 'reserve hash includes id' do
      result = client.create_reserve
      expect(result[:reserve][:id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'accepts custom max_energy' do
      result = client.create_reserve(max_energy: 500.0)
      expect(result[:reserve][:max_energy]).to eq(500.0)
    end

    it 'accepts custom efficiency' do
      result = client.create_reserve(efficiency: 0.8)
      expect(result[:reserve][:efficiency]).to be_within(0.001).of(0.8)
    end
  end

  describe '#spend_energy' do
    let(:reserve_id) { client.create_reserve[:reserve][:id] }

    it 'returns success: true for valid operation' do
      result = client.spend_energy(reserve_id: reserve_id, operation_type: :perception)
      expect(result[:success]).to be true
    end

    it 'returns actual_spent' do
      result = client.spend_energy(reserve_id: reserve_id, operation_type: :perception)
      expect(result[:actual_spent]).to be > 0.0
    end

    it 'returns current_energy' do
      result = client.spend_energy(reserve_id: reserve_id, operation_type: :reasoning)
      expect(result[:current_energy]).to be < 1000.0
    end

    it 'returns state' do
      result = client.spend_energy(reserve_id: reserve_id, operation_type: :decision)
      expect(result[:state]).to be_a(Symbol)
    end

    it 'returns success: false for unknown operation type' do
      result = client.spend_energy(reserve_id: reserve_id, operation_type: :unknown)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/Unknown operation type/)
    end

    it 'returns success: false for unknown reserve_id' do
      result = client.spend_energy(reserve_id: 'fake', operation_type: :perception)
      expect(result[:success]).to be false
    end

    it 'handles all defined operation types' do
      %i[perception memory_retrieval reasoning creativity decision communication].each do |op|
        result = client.spend_energy(reserve_id: reserve_id, operation_type: op)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#recover' do
    let(:reserve_id) { client.create_reserve[:reserve][:id] }

    before { client.spend_energy(reserve_id: reserve_id, operation_type: :creativity) }

    it 'returns success: true' do
      result = client.recover(reserve_id: reserve_id)
      expect(result[:success]).to be true
    end

    it 'returns energy_gained' do
      result = client.recover(reserve_id: reserve_id)
      expect(result[:energy_gained]).to be > 0.0
    end

    it 'returns success: false for unknown reserve' do
      result = client.recover(reserve_id: 'fake')
      expect(result[:success]).to be false
    end

    it 'accepts custom duration' do
      r1 = client.recover(reserve_id: reserve_id, duration: 1.0)
      r2 = client.recover(reserve_id: reserve_id, duration: 3.0)
      expect(r2[:energy_gained]).to be >= r1[:energy_gained]
    end
  end

  describe '#catabolize' do
    let(:reserve_id) { client.create_reserve[:reserve][:id] }

    it 'returns success: true' do
      result = client.catabolize(reserve_id: reserve_id)
      expect(result[:success]).to be true
    end

    it 'returns energy_gained' do
      result = client.catabolize(reserve_id: reserve_id, complexity: 1.0)
      expect(result[:energy_gained]).to be > 0.0
    end

    it 'returns success: false for unknown reserve' do
      result = client.catabolize(reserve_id: 'fake')
      expect(result[:success]).to be false
    end

    it 'higher complexity yields more energy' do
      r1 = client.create_reserve(max_energy: 100.0)[:reserve][:id]
      r2 = client.create_reserve(max_energy: 100.0)[:reserve][:id]
      client.spend_energy(reserve_id: r1, operation_type: :creativity)
      client.spend_energy(reserve_id: r2, operation_type: :creativity)
      low  = client.catabolize(reserve_id: r1, complexity: 1.0)
      high = client.catabolize(reserve_id: r2, complexity: 5.0)
      expect(high[:energy_gained]).to be > low[:energy_gained]
    end
  end

  describe '#anabolize' do
    let(:reserve_id) { client.create_reserve[:reserve][:id] }

    it 'returns success: true' do
      result = client.anabolize(reserve_id: reserve_id)
      expect(result[:success]).to be true
    end

    it 'returns structure_value' do
      result = client.anabolize(reserve_id: reserve_id, energy_cost: 10.0)
      expect(result[:structure_value]).to be > 0.0
    end

    it 'returns success: false when insufficient energy' do
      small_reserve = client.create_reserve(max_energy: 3.0)[:reserve][:id]
      result = client.anabolize(reserve_id: small_reserve, energy_cost: 5.0)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/insufficient energy/)
    end

    it 'returns success: false for unknown reserve' do
      result = client.anabolize(reserve_id: 'fake')
      expect(result[:success]).to be false
    end
  end

  describe '#metabolic_status' do
    let(:reserve_id) { client.create_reserve[:reserve][:id] }

    it 'returns success: true' do
      result = client.metabolic_status(reserve_id: reserve_id)
      expect(result[:success]).to be true
    end

    it 'returns reserve hash' do
      result = client.metabolic_status(reserve_id: reserve_id)
      expect(result[:reserve]).to be_a(Hash)
    end

    it 'returns efficiency_history' do
      result = client.metabolic_status(reserve_id: reserve_id)
      expect(result[:efficiency_history]).to be_a(Array)
    end

    it 'returns success: false for unknown reserve' do
      result = client.metabolic_status(reserve_id: 'fake')
      expect(result[:success]).to be false
    end
  end

  describe '#run_cycle' do
    let(:reserve_id) { client.create_reserve[:reserve][:id] }

    it 'returns success: true' do
      result = client.run_cycle(reserve_id: reserve_id, operations: %i[perception reasoning])
      expect(result[:success]).to be true
    end

    it 'returns cycle_count' do
      result = client.run_cycle(reserve_id: reserve_id, operations: %i[perception])
      expect(result[:cycle_count]).to be >= 1
    end

    it 'returns reserve_state' do
      result = client.run_cycle(reserve_id: reserve_id, operations: [])
      expect(result[:reserve_state]).to be_a(Symbol)
    end

    it 'returns reserve_energy' do
      result = client.run_cycle(reserve_id: reserve_id, operations: [])
      expect(result[:reserve_energy]).to be_a(Float)
    end

    it 'handles empty operations list' do
      result = client.run_cycle(reserve_id: reserve_id, operations: [])
      expect(result[:success]).to be true
    end

    it 'returns success: false for unknown reserve' do
      result = client.run_cycle(reserve_id: 'fake', operations: [])
      expect(result[:success]).to be false
    end
  end

  describe '#run_all_cycles' do
    it 'returns success: true and zero counts when no reserves exist' do
      result = client.run_all_cycles
      expect(result[:success]).to be true
      expect(result[:cycled]).to eq(0)
      expect(result[:reserves]).to eq(0)
      expect(result[:results]).to eq([])
      expect(result[:failures]).to eq([])
    end

    it 'cycles all existing reserves' do
      client.create_reserve
      client.create_reserve
      result = client.run_all_cycles
      expect(result[:reserves]).to eq(2)
      expect(result[:cycled]).to eq(2)
    end

    it 'returns cycled count equal to reserves count on success' do
      client.create_reserve
      result = client.run_all_cycles
      expect(result[:cycled]).to eq(result[:reserves])
    end

    it 'returns success: true with populated results and empty failures' do
      client.create_reserve
      result = client.run_all_cycles
      expect(result[:success]).to be true
      expect(result[:results]).to be_an(Array)
      expect(result[:results].size).to eq(1)
      expect(result[:failures]).to eq([])
    end
  end
end
