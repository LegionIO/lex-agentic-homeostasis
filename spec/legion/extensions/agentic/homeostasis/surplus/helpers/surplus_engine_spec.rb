# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Surplus::Helpers::SurplusEngine do
  subject(:engine) { described_class.new }

  describe '#available_surplus' do
    it 'starts at TOTAL_CAPACITY minus MIN_RESERVE' do
      expected = (Legion::Extensions::Agentic::Homeostasis::Surplus::Helpers::Constants::TOTAL_CAPACITY -
                  Legion::Extensions::Agentic::Homeostasis::Surplus::Helpers::Constants::MIN_RESERVE).round(10)
      expect(engine.available_surplus).to eq(expected)
    end

    it 'decreases after commit' do
      before = engine.available_surplus
      engine.commit!(amount: 0.2)
      expect(engine.available_surplus).to be < before
    end
  end

  describe '#surplus_quality' do
    it 'returns 1.0 when nothing is committed' do
      expect(engine.surplus_quality).to eq(1.0)
    end

    it 'decreases as committed increases' do
      engine.commit!(amount: 0.5)
      expect(engine.surplus_quality).to be < 1.0
    end
  end

  describe '#allocate!' do
    it 'returns allocated: true for valid type with sufficient surplus' do
      result = engine.allocate!(activity_type: :exploration, amount: 0.1)
      expect(result[:allocated]).to be true
      expect(result[:allocation_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns error for invalid allocation type' do
      result = engine.allocate!(activity_type: :invalid, amount: 0.1)
      expect(result[:allocated]).to be false
      expect(result[:reason]).to eq(:invalid_type)
    end

    it 'returns below_threshold when surplus is too low' do
      engine.commit!(amount: 0.9)
      result = engine.allocate!(activity_type: :exploration, amount: 0.05)
      expect(result[:allocated]).to be false
      expect(result[:reason]).to eq(:below_threshold)
    end

    it 'includes quality in result' do
      result = engine.allocate!(activity_type: :creative, amount: 0.1)
      expect(result[:quality]).to be_between(0.0, 1.0)
    end
  end

  describe '#release!' do
    it 'releases an active allocation' do
      alloc = engine.allocate!(activity_type: :consolidation, amount: 0.1)
      result = engine.release!(allocation_id: alloc[:allocation_id])
      expect(result[:released]).to be true
    end

    it 'returns not_found for unknown id' do
      result = engine.release!(allocation_id: 'nonexistent')
      expect(result[:released]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'returns already_released for double release' do
      alloc = engine.allocate!(activity_type: :speculation, amount: 0.1)
      engine.release!(allocation_id: alloc[:allocation_id])
      result = engine.release!(allocation_id: alloc[:allocation_id])
      expect(result[:released]).to be false
      expect(result[:reason]).to eq(:already_released)
    end
  end

  describe '#commit!' do
    it 'increases committed and decreases surplus' do
      surplus_before = engine.available_surplus
      result = engine.commit!(amount: 0.3)
      expect(result[:committed]).to eq(0.3)
      expect(result[:available_surplus]).to be < surplus_before
    end
  end

  describe '#uncommit!' do
    it 'decreases committed and increases surplus' do
      engine.commit!(amount: 0.4)
      committed_before = engine.committed
      result = engine.uncommit!(amount: 0.2)
      expect(result[:committed]).to be < committed_before
    end

    it 'does not go below zero' do
      result = engine.uncommit!(amount: 1.0)
      expect(result[:committed]).to eq(0.0)
    end
  end

  describe '#replenish!' do
    it 'reduces committed by REPLENISH_RATE' do
      engine.commit!(amount: 0.5)
      before = engine.committed
      engine.replenish!
      expect(engine.committed).to be < before
    end

    it 'returns gained amount' do
      engine.commit!(amount: 0.3)
      result = engine.replenish!
      expect(result[:gained]).to eq(Legion::Extensions::Agentic::Homeostasis::Surplus::Helpers::Constants::REPLENISH_RATE)
    end

    it 'does not go below zero committed' do
      engine.replenish!
      expect(engine.committed).to eq(0.0)
    end
  end

  describe '#deplete!' do
    it 'increases committed by amount' do
      before = engine.committed
      engine.deplete!(amount: 0.1)
      expect(engine.committed).to be > before
    end

    it 'does not exceed available surplus' do
      result = engine.deplete!(amount: 2.0)
      expect(engine.available_surplus).to be >= 0.0
      expect(result[:depleted]).to be true
    end
  end

  describe '#surplus_report' do
    it 'returns all required fields' do
      report = engine.surplus_report
      expect(report).to include(
        :total_capacity, :committed, :reserved, :active_allocated,
        :available_surplus, :surplus_label, :quality, :quality_label, :allocation_count
      )
    end

    it 'surplus_label reflects current amount' do
      report = engine.surplus_report
      expect(report[:surplus_label]).to be_a(Symbol)
    end
  end

  describe '#to_h' do
    it 'includes allocations hash' do
      engine.allocate!(activity_type: :maintenance, amount: 0.1)
      h = engine.to_h
      expect(h[:allocations]).to be_a(Hash)
      expect(h[:allocations].size).to eq(1)
    end
  end
end
