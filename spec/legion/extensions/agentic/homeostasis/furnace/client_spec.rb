# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Furnace::Client do
  subject(:client) { described_class.new }

  it 'initializes with a FurnaceEngine' do
    expect(client.engine).to be_a(Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::FurnaceEngine)
  end

  it 'includes the CognitiveFurnace runner' do
    expect(client).to respond_to(:add_ore)
    expect(client).to respond_to(:create_crucible)
    expect(client).to respond_to(:load_ore)
    expect(client).to respond_to(:heat)
    expect(client).to respond_to(:smelt)
    expect(client).to respond_to(:list_ores)
    expect(client).to respond_to(:furnace_status)
  end

  describe 'end-to-end smelting workflow' do
    it 'adds ore, creates crucible, loads, heats, and smelts' do
      engine_opts = { engine: client.engine }

      ore_result = client.add_ore(ore_type: :hypothesis, domain: 'physics', content: 'gravity constant', **engine_opts)
      expect(ore_result[:success]).to be true

      crucible_result = client.create_crucible(capacity: 5, **engine_opts)
      expect(crucible_result[:success]).to be true

      load_result = client.load_ore(
        ore_id:      ore_result[:ore_id],
        crucible_id: crucible_result[:crucible_id],
        **engine_opts
      )
      expect(load_result[:success]).to be true

      # Heat to smelt threshold
      7.times { client.heat(crucible_id: crucible_result[:crucible_id], **engine_opts) }

      smelt_result = client.smelt(crucible_id: crucible_result[:crucible_id], **engine_opts)
      expect(smelt_result[:success]).to be true
      expect(smelt_result[:alloy][:alloy_type]).to eq(:theory)
    end

    it 'tracks alloy in history after smelting' do
      engine_opts = { engine: client.engine }
      ore_result = client.add_ore(ore_type: :data, domain: 'stats', content: 'sample', **engine_opts)
      cid = client.create_crucible(temperature: 0.7, **engine_opts)[:crucible_id]
      client.load_ore(ore_id: ore_result[:ore_id], crucible_id: cid, **engine_opts)
      client.smelt(crucible_id: cid, **engine_opts)
      status = client.furnace_status(**engine_opts)
      expect(status[:report][:alloy_count]).to eq(1)
    end

    it 'returns overheated reason when temperature is too high' do
      engine_opts = { engine: client.engine }
      ore_result = client.add_ore(ore_type: :experience, domain: 'test', content: 'x', **engine_opts)
      cid = client.create_crucible(temperature: 0.96, **engine_opts)[:crucible_id]
      client.load_ore(ore_id: ore_result[:ore_id], crucible_id: cid, **engine_opts)
      result = client.smelt(crucible_id: cid, **engine_opts)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:overheated)
    end
  end

  describe 'multiple ores and alloy blending' do
    it 'smelts multiple ores into a single alloy' do
      engine_opts = { engine: client.engine }
      cid = client.create_crucible(temperature: 0.7, capacity: 5, **engine_opts)[:crucible_id]

      3.times do |i|
        ore = client.add_ore(ore_type: :observation, domain: 'test', content: "obs #{i}", **engine_opts)
        client.load_ore(ore_id: ore[:ore_id], crucible_id: cid, **engine_opts)
      end

      result = client.smelt(crucible_id: cid, **engine_opts)
      expect(result[:success]).to be true
      expect(result[:alloy][:ore_count]).to eq(3)
    end
  end
end
