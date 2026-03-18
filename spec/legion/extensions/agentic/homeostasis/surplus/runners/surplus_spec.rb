# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/surplus/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Surplus::Runners::Surplus do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Surplus::Client.new }

  describe '#surplus_status' do
    it 'returns a surplus report hash' do
      result = client.surplus_status
      expect(result).to include(:available_surplus, :surplus_label, :quality, :quality_label)
    end

    it 'available_surplus is between 0 and 1' do
      result = client.surplus_status
      expect(result[:available_surplus]).to be_between(0.0, 1.0)
    end
  end

  describe '#allocate_surplus' do
    it 'allocates surplus for a valid activity type' do
      result = client.allocate_surplus(activity_type: :exploration, amount: 0.1)
      expect(result[:allocated]).to be true
      expect(result[:allocation_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns error for invalid activity type' do
      result = client.allocate_surplus(activity_type: :bogus, amount: 0.1)
      expect(result[:allocated]).to be false
    end

    it 'uses default amount of SURPLUS_THRESHOLD' do
      result = client.allocate_surplus(activity_type: :creative)
      expect(result[:allocated]).to be true
    end
  end

  describe '#release_surplus' do
    it 'releases an active allocation' do
      alloc = client.allocate_surplus(activity_type: :consolidation, amount: 0.1)
      result = client.release_surplus(allocation_id: alloc[:allocation_id])
      expect(result[:released]).to be true
    end

    it 'returns not_found for unknown allocation id' do
      result = client.release_surplus(allocation_id: 'no-such-id')
      expect(result[:released]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#commit_capacity' do
    it 'commits capacity and reduces available surplus' do
      before = client.surplus_status[:available_surplus]
      client.commit_capacity(amount: 0.2)
      after = client.surplus_status[:available_surplus]
      expect(after).to be < before
    end
  end

  describe '#uncommit_capacity' do
    it 'uncommits capacity and increases available surplus' do
      client.commit_capacity(amount: 0.3)
      before = client.surplus_status[:available_surplus]
      client.uncommit_capacity(amount: 0.15)
      after = client.surplus_status[:available_surplus]
      expect(after).to be > before
    end
  end

  describe '#replenish_surplus' do
    it 'returns replenished: true' do
      result = client.replenish_surplus
      expect(result[:replenished]).to be true
    end

    it 'includes gained amount' do
      client.commit_capacity(amount: 0.3)
      result = client.replenish_surplus
      expect(result[:gained]).to be >= 0.0
    end
  end

  describe '#deplete_surplus' do
    it 'reduces available surplus' do
      before = client.surplus_status[:available_surplus]
      client.deplete_surplus(amount: 0.1)
      after = client.surplus_status[:available_surplus]
      expect(after).to be < before
    end

    it 'returns depleted: true' do
      result = client.deplete_surplus(amount: 0.05)
      expect(result[:depleted]).to be true
    end
  end

  describe '#surplus_allocations' do
    it 'returns empty allocations initially' do
      result = client.surplus_allocations
      expect(result[:count]).to eq(0)
      expect(result[:allocations]).to eq([])
    end

    it 'lists active allocations' do
      client.allocate_surplus(activity_type: :speculation, amount: 0.1)
      client.allocate_surplus(activity_type: :maintenance, amount: 0.1)
      result = client.surplus_allocations
      expect(result[:count]).to eq(2)
    end

    it 'excludes released allocations' do
      alloc = client.allocate_surplus(activity_type: :exploration, amount: 0.1)
      client.release_surplus(allocation_id: alloc[:allocation_id])
      result = client.surplus_allocations
      expect(result[:count]).to eq(0)
    end
  end
end
