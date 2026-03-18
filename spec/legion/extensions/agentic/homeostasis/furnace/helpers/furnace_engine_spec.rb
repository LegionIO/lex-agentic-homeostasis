# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::FurnaceEngine do
  subject(:engine) { described_class.new }

  def add_sample_ore(type: :experience, purity: 0.6)
    engine.add_ore(ore_type: type, domain: 'test', content: 'sample content', purity: purity)
  end

  def add_and_load_ore(crucible_id:, type: :experience, purity: 0.6)
    result = add_sample_ore(type: type, purity: purity)
    engine.load_ore(ore_id: result[:ore_id], crucible_id: crucible_id)
    result[:ore_id]
  end

  describe '#initialize' do
    it 'starts with empty ores' do
      expect(engine.ores).to be_empty
    end

    it 'starts with empty crucibles' do
      expect(engine.crucibles).to be_empty
    end

    it 'starts with empty alloy_history' do
      expect(engine.alloy_history).to be_empty
    end
  end

  describe '#add_ore' do
    it 'adds an ore and returns success' do
      result = add_sample_ore
      expect(result[:added]).to be true
      expect(result[:ore_id]).to be_a(String)
    end

    it 'stores the ore in ores hash' do
      result = add_sample_ore
      expect(engine.ores[result[:ore_id]]).to be_a(Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Ore)
    end

    it 'rejects when ore store is full' do
      stub_const('Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::MAX_ORES', 1)
      add_sample_ore
      result = add_sample_ore
      expect(result[:added]).to be false
      expect(result[:reason]).to eq(:ore_store_full)
    end

    it 'raises ArgumentError for invalid ore_type' do
      expect do
        engine.add_ore(ore_type: :invalid, domain: 'x', content: 'y')
      end.to raise_error(ArgumentError)
    end

    it 'accepts all 5 ore types' do
      Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::ORE_TYPES.each do |t|
        r = engine.add_ore(ore_type: t, domain: 'x', content: 'y')
        expect(r[:added]).to be true
      end
    end
  end

  describe '#create_crucible' do
    it 'creates a crucible and returns success' do
      result = engine.create_crucible
      expect(result[:created]).to be true
      expect(result[:crucible_id]).to be_a(String)
    end

    it 'stores the crucible' do
      result = engine.create_crucible
      expect(engine.crucibles[result[:crucible_id]]).to be_a(Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Crucible)
    end

    it 'rejects when at max capacity' do
      stub_const('Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::MAX_CRUCIBLES', 1)
      engine.create_crucible
      result = engine.create_crucible
      expect(result[:created]).to be false
      expect(result[:reason]).to eq(:crucible_store_full)
    end

    it 'accepts custom capacity and temperature' do
      result = engine.create_crucible(capacity: 5, temperature: 0.3)
      crucible = engine.crucibles[result[:crucible_id]]
      expect(crucible.capacity).to eq(5)
      expect(crucible.temperature).to be_within(0.001).of(0.3)
    end
  end

  describe '#load_ore' do
    let(:crucible_id) { engine.create_crucible[:crucible_id] }

    it 'loads ore into crucible' do
      ore_result = add_sample_ore
      result = engine.load_ore(ore_id: ore_result[:ore_id], crucible_id: crucible_id)
      expect(result[:loaded]).to be true
    end

    it 'returns not found for missing ore' do
      result = engine.load_ore(ore_id: 'nonexistent', crucible_id: crucible_id)
      expect(result[:loaded]).to be false
      expect(result[:reason]).to eq(:ore_not_found)
    end

    it 'returns not found for missing crucible' do
      ore_result = add_sample_ore
      result = engine.load_ore(ore_id: ore_result[:ore_id], crucible_id: 'nonexistent')
      expect(result[:loaded]).to be false
      expect(result[:reason]).to eq(:crucible_not_found)
    end
  end

  describe '#heat_crucible' do
    let(:crucible_id) { engine.create_crucible[:crucible_id] }

    it 'increases crucible temperature' do
      result = engine.heat_crucible(crucible_id: crucible_id)
      expect(result[:heated]).to be true
      expect(result[:after]).to be > result[:before]
    end

    it 'returns label' do
      result = engine.heat_crucible(crucible_id: crucible_id)
      expect(result[:label]).to be_a(Symbol)
    end

    it 'returns not found for missing crucible' do
      result = engine.heat_crucible(crucible_id: 'nonexistent')
      expect(result[:heated]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'accepts custom rate' do
      result = engine.heat_crucible(crucible_id: crucible_id, rate: 0.3)
      expect(result[:after]).to be_within(0.001).of(0.3)
    end

    it 'flags overheated when above DESTROY_THRESHOLD' do
      # Heat many times
      9.times { engine.heat_crucible(crucible_id: crucible_id, rate: 0.1) }
      result = engine.heat_crucible(crucible_id: crucible_id, rate: 0.1)
      expect(result).to have_key(:overheated)
    end
  end

  describe '#cool_crucible' do
    let(:crucible_id) { engine.create_crucible(temperature: 0.5)[:crucible_id] }

    it 'decreases crucible temperature' do
      result = engine.cool_crucible(crucible_id: crucible_id)
      expect(result[:cooled]).to be true
      expect(result[:after]).to be < result[:before]
    end

    it 'returns not found for missing crucible' do
      result = engine.cool_crucible(crucible_id: 'nonexistent')
      expect(result[:cooled]).to be false
    end
  end

  describe '#smelt' do
    let(:crucible_id) { engine.create_crucible(temperature: 0.7)[:crucible_id] }

    it 'smelts ores into an alloy' do
      add_and_load_ore(crucible_id: crucible_id)
      result = engine.smelt(crucible_id: crucible_id)
      expect(result[:smelted]).to be true
      expect(result[:alloy]).to include(:alloy_id, :alloy_type)
    end

    it 'adds alloy to history' do
      add_and_load_ore(crucible_id: crucible_id)
      engine.smelt(crucible_id: crucible_id)
      expect(engine.alloy_history.size).to eq(1)
    end

    it 'removes smelted ores from ore store' do
      ore_id = add_and_load_ore(crucible_id: crucible_id)
      engine.smelt(crucible_id: crucible_id)
      expect(engine.ores[ore_id]).to be_nil
    end

    it 'destroys ores when overheated' do
      hot_id = engine.create_crucible(temperature: 0.96)[:crucible_id]
      ore_id = add_and_load_ore(crucible_id: hot_id)
      result = engine.smelt(crucible_id: hot_id)
      expect(result[:smelted]).to be false
      expect(result[:reason]).to eq(:overheated)
      expect(engine.ores[ore_id]).to be_nil
    end

    it 'returns not found for missing crucible' do
      result = engine.smelt(crucible_id: 'nonexistent')
      expect(result[:smelted]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#cool_all!' do
    it 'cools all crucibles' do
      engine.create_crucible(temperature: 0.5)
      engine.create_crucible(temperature: 0.7)
      result = engine.cool_all!
      expect(result[:cooled]).to eq(2)
      expect(result[:total]).to eq(2)
    end

    it 'skips already-cold crucibles' do
      engine.create_crucible(temperature: 0.0)
      result = engine.cool_all!
      expect(result[:cooled]).to eq(0)
    end
  end

  describe '#purest_ores' do
    it 'returns ores sorted by purity descending' do
      add_sample_ore(purity: 0.3)
      add_sample_ore(purity: 0.9)
      add_sample_ore(purity: 0.6)
      ores = engine.purest_ores
      expect(ores.first[:purity]).to be >= ores.last[:purity]
    end

    it 'respects limit' do
      5.times { add_sample_ore }
      expect(engine.purest_ores(limit: 3).size).to eq(3)
    end

    it 'returns hashes' do
      add_sample_ore
      expect(engine.purest_ores.first).to be_a(Hash)
    end
  end

  describe '#hottest_crucibles' do
    it 'returns crucibles sorted by temperature descending' do
      engine.create_crucible(temperature: 0.2)
      engine.create_crucible(temperature: 0.8)
      engine.create_crucible(temperature: 0.5)
      crucibles = engine.hottest_crucibles
      expect(crucibles.first[:temperature]).to be >= crucibles.last[:temperature]
    end

    it 'respects limit' do
      5.times { engine.create_crucible }
      expect(engine.hottest_crucibles(limit: 2).size).to eq(2)
    end
  end

  describe '#furnace_report' do
    it 'returns a report hash with expected keys' do
      report = engine.furnace_report
      expect(report).to include(
        :ore_count, :crucible_count, :alloy_count,
        :avg_ore_purity, :avg_temperature,
        :optimal_crucibles, :overheated_crucibles,
        :ore_capacity, :crucible_capacity
      )
    end

    it 'reflects current state' do
      add_sample_ore
      engine.create_crucible
      report = engine.furnace_report
      expect(report[:ore_count]).to eq(1)
      expect(report[:crucible_count]).to eq(1)
    end

    it 'counts optimal crucibles' do
      engine.create_crucible(temperature: 0.7)
      engine.create_crucible(temperature: 0.1)
      expect(engine.furnace_report[:optimal_crucibles]).to eq(1)
    end

    it 'counts overheated crucibles' do
      engine.create_crucible(temperature: 0.97)
      expect(engine.furnace_report[:overheated_crucibles]).to eq(1)
    end

    it 'reports capacity constants' do
      report = engine.furnace_report
      expect(report[:ore_capacity]).to eq(Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::MAX_ORES)
      expect(report[:crucible_capacity]).to eq(Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Constants::MAX_CRUCIBLES)
    end
  end
end
