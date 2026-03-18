# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Furnace::Runners::CognitiveFurnace do
  let(:engine) { Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::FurnaceEngine.new }
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Furnace::Client.new }

  def via_client_engine
    { engine: client.engine }
  end

  describe '#add_ore' do
    it 'adds an ore successfully' do
      result = client.add_ore(ore_type: :experience, domain: 'test', content: 'hello', **via_client_engine)
      expect(result[:success]).to be true
      expect(result[:ore_id]).to be_a(String)
    end

    it 'returns failure for missing ore_type' do
      result = client.add_ore(domain: 'test', content: 'x')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_ore_type)
    end

    it 'returns failure for missing domain' do
      result = client.add_ore(ore_type: :data, content: 'x')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_domain)
    end

    it 'returns failure for missing content' do
      result = client.add_ore(ore_type: :data, domain: 'x')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_content)
    end

    it 'returns failure for invalid ore_type' do
      result = client.add_ore(ore_type: :invalid_type, domain: 'x', content: 'y')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_ore_type)
    end

    it 'includes valid types in error response' do
      result = client.add_ore(ore_type: :invalid_type, domain: 'x', content: 'y')
      expect(result[:valid]).to eq(Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::ORE_TYPES)
    end

    it 'accepts all valid ore types' do
      Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::ORE_TYPES.each do |t|
        result = client.add_ore(ore_type: t, domain: 'x', content: 'y', **via_client_engine)
        expect(result[:success]).to be true
      end
    end

    it 'accepts string ore_type and converts to symbol' do
      result = client.add_ore(ore_type: 'experience', domain: 'x', content: 'y', **via_client_engine)
      expect(result[:success]).to be true
    end

    it 'accepts custom purity' do
      result = client.add_ore(ore_type: :data, domain: 'x', content: 'y', purity: 0.9, **via_client_engine)
      expect(result[:success]).to be true
      expect(result[:ore][:purity]).to eq(0.9)
    end
  end

  describe '#create_crucible' do
    it 'creates a crucible successfully' do
      result = client.create_crucible(**via_client_engine)
      expect(result[:success]).to be true
      expect(result[:crucible_id]).to be_a(String)
    end

    it 'accepts custom capacity' do
      result = client.create_crucible(capacity: 20, **via_client_engine)
      expect(result[:success]).to be true
      expect(result[:crucible][:capacity]).to eq(20)
    end

    it 'accepts custom temperature' do
      result = client.create_crucible(temperature: 0.4, **via_client_engine)
      expect(result[:success]).to be true
      expect(result[:crucible][:temperature]).to be_within(0.001).of(0.4)
    end
  end

  describe '#load_ore' do
    let(:ore_id) { client.add_ore(ore_type: :data, domain: 'x', content: 'y', **via_client_engine)[:ore_id] }
    let(:crucible_id) { client.create_crucible(**via_client_engine)[:crucible_id] }

    it 'loads ore into crucible' do
      result = client.load_ore(ore_id: ore_id, crucible_id: crucible_id, **via_client_engine)
      expect(result[:success]).to be true
    end

    it 'returns failure for missing ore_id' do
      result = client.load_ore(crucible_id: crucible_id)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_ore_id)
    end

    it 'returns failure for missing crucible_id' do
      result = client.load_ore(ore_id: ore_id)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_crucible_id)
    end

    it 'returns failure for nonexistent ore' do
      result = client.load_ore(ore_id: 'bad', crucible_id: crucible_id, **via_client_engine)
      expect(result[:success]).to be false
    end

    it 'returns failure for nonexistent crucible' do
      result = client.load_ore(ore_id: ore_id, crucible_id: 'bad', **via_client_engine)
      expect(result[:success]).to be false
    end
  end

  describe '#heat' do
    let(:crucible_id) { client.create_crucible(**via_client_engine)[:crucible_id] }

    it 'heats the crucible' do
      result = client.heat(crucible_id: crucible_id, **via_client_engine)
      expect(result[:success]).to be true
      expect(result[:after]).to be > result[:before]
    end

    it 'returns failure for missing crucible_id' do
      result = client.heat
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_crucible_id)
    end

    it 'returns failure for nonexistent crucible' do
      result = client.heat(crucible_id: 'nonexistent', **via_client_engine)
      expect(result[:success]).to be false
    end

    it 'accepts custom rate' do
      result = client.heat(crucible_id: crucible_id, rate: 0.3, **via_client_engine)
      expect(result[:after]).to be_within(0.001).of(0.3)
    end
  end

  describe '#smelt' do
    it 'returns failure for missing crucible_id' do
      result = client.smelt
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_crucible_id)
    end

    it 'returns failure for invalid alloy_type' do
      crucible_id = client.create_crucible(**via_client_engine)[:crucible_id]
      result = client.smelt(crucible_id: crucible_id, alloy_type: :invalid_alloy, **via_client_engine)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_alloy_type)
    end

    it 'smelts ores into alloy' do
      cid = client.create_crucible(temperature: 0.7, **via_client_engine)[:crucible_id]
      client.add_ore(ore_type: :observation, domain: 'test', content: 'data point', **via_client_engine).tap do |r|
        client.load_ore(ore_id: r[:ore_id], crucible_id: cid, **via_client_engine)
      end
      result = client.smelt(crucible_id: cid, **via_client_engine)
      expect(result[:success]).to be true
    end

    it 'returns failure when temperature too low' do
      cid = client.create_crucible(**via_client_engine)[:crucible_id]
      client.add_ore(ore_type: :data, domain: 'x', content: 'y', **via_client_engine).tap do |r|
        client.load_ore(ore_id: r[:ore_id], crucible_id: cid, **via_client_engine)
      end
      result = client.smelt(crucible_id: cid, **via_client_engine)
      expect(result[:success]).to be false
    end

    it 'accepts valid alloy_type override' do
      cid = client.create_crucible(temperature: 0.7, **via_client_engine)[:crucible_id]
      client.add_ore(ore_type: :intuition, domain: 'test', content: 'hunch', **via_client_engine).tap do |r|
        client.load_ore(ore_id: r[:ore_id], crucible_id: cid, **via_client_engine)
      end
      result = client.smelt(crucible_id: cid, alloy_type: :insight, **via_client_engine)
      expect(result[:success]).to be true
      expect(result[:alloy][:alloy_type]).to eq(:insight)
    end
  end

  describe '#list_ores' do
    it 'returns empty list when no ores' do
      result = client.list_ores(**via_client_engine)
      expect(result[:success]).to be true
      expect(result[:ores]).to be_empty
    end

    it 'returns added ores' do
      client.add_ore(ore_type: :data, domain: 'x', content: 'y', **via_client_engine)
      result = client.list_ores(**via_client_engine)
      expect(result[:ores].size).to eq(1)
    end

    it 'respects limit' do
      5.times { client.add_ore(ore_type: :data, domain: 'x', content: 'y', **via_client_engine) }
      result = client.list_ores(limit: 3, **via_client_engine)
      expect(result[:ores].size).to be <= 3
    end

    it 'returns total count' do
      3.times { client.add_ore(ore_type: :data, domain: 'x', content: 'y', **via_client_engine) }
      result = client.list_ores(**via_client_engine)
      expect(result[:total]).to eq(3)
    end
  end

  describe '#furnace_status' do
    it 'returns success with report' do
      result = client.furnace_status(**via_client_engine)
      expect(result[:success]).to be true
      expect(result[:report]).to include(:ore_count, :crucible_count, :alloy_count)
    end

    it 'reflects actual counts' do
      client.add_ore(ore_type: :experience, domain: 'x', content: 'y', **via_client_engine)
      client.create_crucible(**via_client_engine)
      result = client.furnace_status(**via_client_engine)
      expect(result[:report][:ore_count]).to eq(1)
      expect(result[:report][:crucible_count]).to eq(1)
    end
  end
end
