# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Surplus::Helpers::Allocation do
  subject(:allocation) { described_class.new(activity_type: :exploration, amount: 0.2, quality: 0.75) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(allocation.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores activity_type' do
      expect(allocation.activity_type).to eq(:exploration)
    end

    it 'rounds amount to 10 decimal places' do
      expect(allocation.amount).to eq(0.2)
    end

    it 'rounds quality to 10 decimal places' do
      expect(allocation.quality).to eq(0.75)
    end

    it 'sets created_at' do
      expect(allocation.created_at).to be_a(Time)
    end

    it 'starts active' do
      expect(allocation.active?).to be true
    end
  end

  describe '#release!' do
    it 'deactivates the allocation' do
      allocation.release!
      expect(allocation.active?).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = allocation.to_h
      expect(h).to include(:id, :activity_type, :amount, :quality, :active, :created_at)
    end

    it 'reflects active state' do
      expect(allocation.to_h[:active]).to be true
      allocation.release!
      expect(allocation.to_h[:active]).to be false
    end
  end
end
