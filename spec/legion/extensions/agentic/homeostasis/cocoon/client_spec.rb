# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Cocoon::Client do
  subject(:client) { described_class.new }

  describe 'runner interface' do
    it 'responds to create_cocoon' do
      expect(client).to respond_to(:create_cocoon)
    end

    it 'responds to gestate_all' do
      expect(client).to respond_to(:gestate_all)
    end

    it 'responds to harvest_ready' do
      expect(client).to respond_to(:harvest_ready)
    end

    it 'responds to force_emerge' do
      expect(client).to respond_to(:force_emerge)
    end

    it 'responds to cocoon_status' do
      expect(client).to respond_to(:cocoon_status)
    end

    it 'responds to list_by_stage' do
      expect(client).to respond_to(:list_by_stage)
    end
  end

  describe '#create_cocoon' do
    it 'returns success true' do
      result = client.create_cocoon(cocoon_type: :chrysalis, domain: :cognitive, content: 'idea')
      expect(result[:success]).to be true
    end

    it 'returns cocoon hash' do
      result = client.create_cocoon(cocoon_type: :silk, domain: :emotional)
      expect(result[:cocoon]).to include(:id, :cocoon_type, :domain, :maturity, :stage)
    end
  end

  describe '#gestate_all' do
    it 'returns success true' do
      client.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      result = client.gestate_all
      expect(result[:success]).to be true
    end

    it 'accepts a custom rate' do
      client.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      result = client.gestate_all(rate: 0.2)
      expect(result[:success]).to be true
    end
  end

  describe '#harvest_ready' do
    it 'returns success true with empty emerged when nothing ready' do
      client.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      result = client.harvest_ready
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'harvests ready cocoons' do
      client.create_cocoon(cocoon_type: :silk, domain: :cognitive, maturity: 1.0)
      result = client.harvest_ready
      expect(result[:count]).to eq(1)
      expect(result[:emerged].first[:success]).to be true
    end
  end

  describe '#force_emerge' do
    it 'force-emerges a valid cocoon' do
      create_result = client.create_cocoon(cocoon_type: :shell, domain: :cognitive)
      id = create_result[:cocoon][:id]
      result = client.force_emerge(id: id)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown id' do
      result = client.force_emerge(id: 'bad-id')
      expect(result[:success]).to be false
    end
  end

  describe '#cocoon_status' do
    it 'returns success true' do
      result = client.cocoon_status
      expect(result[:success]).to be true
    end

    it 'includes total_cocoons' do
      client.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      result = client.cocoon_status
      expect(result[:total_cocoons]).to eq(1)
    end

    it 'includes maturity_label' do
      result = client.cocoon_status
      expect(result).to have_key(:maturity_label)
    end
  end

  describe '#list_by_stage' do
    it 'returns success true' do
      result = client.list_by_stage(stage: :encapsulating)
      expect(result[:success]).to be true
    end

    it 'returns the requested stage name' do
      result = client.list_by_stage(stage: :encapsulating)
      expect(result[:stage]).to eq(:encapsulating)
    end

    it 'returns cocoons in the given stage' do
      client.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      result = client.list_by_stage(stage: :encapsulating)
      expect(result[:count]).to eq(1)
    end

    it 'returns cocoon hashes' do
      client.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      result = client.list_by_stage(stage: :encapsulating)
      expect(result[:cocoons].first).to include(:id, :cocoon_type, :stage)
    end
  end

  describe 'full lifecycle' do
    it 'creates, gestates, and harvests a cocoon' do
      client.create_cocoon(cocoon_type: :chrysalis, domain: :cognitive, content: 'deep insight')
      10.times { client.gestate_all(rate: 0.1) }
      result = client.harvest_ready
      expect(result[:count]).to eq(1)
      expect(result[:emerged].first[:content]).to eq('deep insight')
    end

    it 'correctly reports status after gestation' do
      client.create_cocoon(cocoon_type: :pod, domain: :emotional, content: 'growing concept')
      5.times { client.gestate_all(rate: 0.1) }
      status = client.cocoon_status
      expect(status[:average_maturity]).to be_within(0.01).of(0.5)
    end
  end
end
