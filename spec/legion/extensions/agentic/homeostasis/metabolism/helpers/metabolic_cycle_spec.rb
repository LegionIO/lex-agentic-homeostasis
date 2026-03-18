# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Metabolism::Helpers::MetabolicCycle do
  subject(:cycle) { described_class.new }

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(cycle.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with zero cycle_count' do
      expect(cycle.cycle_count).to eq(0)
    end

    it 'starts with empty operations_log' do
      expect(cycle.operations_log).to eq([])
    end

    it 'starts with zero energy_spent_this_cycle' do
      expect(cycle.energy_spent_this_cycle).to eq(0.0)
    end

    it 'sets started_at' do
      expect(cycle.started_at).to be_a(Time)
    end

    it 'starts with nil completed_at' do
      expect(cycle.completed_at).to be_nil
    end
  end

  describe '#record_operation' do
    it 'adds an entry to operations_log' do
      expect { cycle.record_operation(operation_type: :reasoning, energy_spent: 15.0) }
        .to change { cycle.operations_log.size }.by(1)
    end

    it 'increments cycle_count' do
      expect { cycle.record_operation(operation_type: :perception, energy_spent: 5.0) }
        .to change { cycle.cycle_count }.by(1)
    end

    it 'accumulates energy_spent_this_cycle' do
      cycle.record_operation(operation_type: :perception, energy_spent: 5.0)
      cycle.record_operation(operation_type: :reasoning, energy_spent: 15.0)
      expect(cycle.energy_spent_this_cycle).to be_within(0.001).of(20.0)
    end

    it 'stores operation_type in the log entry' do
      cycle.record_operation(operation_type: :creativity, energy_spent: 20.0)
      expect(cycle.operations_log.last[:operation_type]).to eq(:creativity)
    end

    it 'stores recorded_at in the log entry' do
      cycle.record_operation(operation_type: :decision, energy_spent: 12.0)
      expect(cycle.operations_log.last[:recorded_at]).to be_a(Time)
    end

    it 'rounds energy_spent in the log entry' do
      cycle.record_operation(operation_type: :perception, energy_spent: 5.123456789012345)
      expect(cycle.operations_log.last[:energy_spent]).to be_a(Float)
    end
  end

  describe '#complete!' do
    it 'sets completed_at' do
      cycle.complete!
      expect(cycle.completed_at).to be_a(Time)
    end

    it 'returns a hash' do
      result = cycle.complete!
      expect(result).to be_a(Hash)
    end

    it 'returned hash includes duration_seconds' do
      result = cycle.complete!
      expect(result[:duration_seconds]).to be >= 0.0
    end
  end

  describe '#duration_seconds' do
    it 'returns nil before completion' do
      expect(cycle.duration_seconds).to be_nil
    end

    it 'returns a non-negative float after completion' do
      cycle.complete!
      expect(cycle.duration_seconds).to be >= 0.0
    end
  end

  describe '#average_energy_per_operation' do
    it 'returns 0.0 with no operations' do
      expect(cycle.average_energy_per_operation).to eq(0.0)
    end

    it 'computes average correctly' do
      cycle.record_operation(operation_type: :perception, energy_spent: 10.0)
      cycle.record_operation(operation_type: :reasoning, energy_spent: 20.0)
      expect(cycle.average_energy_per_operation).to be_within(0.001).of(15.0)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = cycle.to_h
      expect(h.keys).to include(:id, :cycle_count, :energy_spent_this_cycle,
                                :average_per_operation, :operations_log,
                                :started_at, :completed_at, :duration_seconds)
    end

    it 'reflects current state' do
      cycle.record_operation(operation_type: :decision, energy_spent: 12.0)
      h = cycle.to_h
      expect(h[:cycle_count]).to eq(1)
    end
  end
end
