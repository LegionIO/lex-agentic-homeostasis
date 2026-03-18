# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Crucible do
  let(:crucible) { described_class.new }
  let(:ore_store) { {} }

  def make_ore(purity: 0.7, type: :experience)
    ore = Legion::Extensions::Agentic::Homeostasis::Furnace::Helpers::Ore.new(
      ore_type: type, domain: 'test', content: 'some content', purity: purity
    )
    ore_store[ore.ore_id] = ore
    ore
  end

  describe '#initialize' do
    it 'creates with default capacity 10' do
      expect(crucible.capacity).to eq(10)
    end

    it 'creates with default temperature 0.0' do
      expect(crucible.temperature).to eq(0.0)
    end

    it 'assigns a uuid crucible_id' do
      expect(crucible.crucible_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'starts with empty ore_ids' do
      expect(crucible.ore_ids).to be_empty
    end

    it 'accepts custom capacity' do
      c = described_class.new(capacity: 5)
      expect(c.capacity).to eq(5)
    end

    it 'accepts custom temperature' do
      c = described_class.new(temperature: 0.5)
      expect(c.temperature).to eq(0.5)
    end

    it 'clamps capacity minimum to 1' do
      c = described_class.new(capacity: 0)
      expect(c.capacity).to eq(1)
    end

    it 'sets created_at' do
      expect(crucible.created_at).to be_a(Time)
    end
  end

  describe '#heat!' do
    it 'increases temperature by HEAT_RATE' do
      crucible.heat!
      expect(crucible.temperature).to be_within(0.001).of(0.1)
    end

    it 'clamps temperature at 1.0' do
      c = described_class.new(temperature: 0.95)
      c.heat!
      expect(c.temperature).to eq(1.0)
    end

    it 'accepts custom rate' do
      crucible.heat!(0.3)
      expect(crucible.temperature).to be_within(0.001).of(0.3)
    end

    it 'returns self for chaining' do
      expect(crucible.heat!).to eq(crucible)
    end
  end

  describe '#cool!' do
    it 'decreases temperature by COOL_RATE' do
      c = described_class.new(temperature: 0.5)
      c.cool!
      expect(c.temperature).to be_within(0.001).of(0.45)
    end

    it 'clamps temperature at 0.0' do
      crucible.cool!
      expect(crucible.temperature).to eq(0.0)
    end

    it 'accepts custom rate' do
      c = described_class.new(temperature: 0.5)
      c.cool!(0.2)
      expect(c.temperature).to be_within(0.001).of(0.3)
    end

    it 'returns self for chaining' do
      expect(crucible.cool!).to eq(crucible)
    end
  end

  describe '#load_ore' do
    it 'loads an ore by id' do
      ore = make_ore
      result = crucible.load_ore(ore.ore_id)
      expect(result[:loaded]).to be true
      expect(crucible.ore_ids).to include(ore.ore_id)
    end

    it 'returns count after loading' do
      ore = make_ore
      result = crucible.load_ore(ore.ore_id)
      expect(result[:count]).to eq(1)
    end

    it 'rejects duplicate ore' do
      ore = make_ore
      crucible.load_ore(ore.ore_id)
      result = crucible.load_ore(ore.ore_id)
      expect(result[:loaded]).to be false
      expect(result[:reason]).to eq(:already_loaded)
    end

    it 'rejects when at capacity' do
      c = described_class.new(capacity: 1)
      ore1 = make_ore
      ore2 = make_ore
      c.load_ore(ore1.ore_id)
      result = c.load_ore(ore2.ore_id)
      expect(result[:loaded]).to be false
      expect(result[:reason]).to eq(:at_capacity)
    end
  end

  describe '#unload_ore' do
    it 'removes ore from crucible' do
      ore = make_ore
      crucible.load_ore(ore.ore_id)
      result = crucible.unload_ore(ore.ore_id)
      expect(result[:unloaded]).to be true
      expect(crucible.ore_ids).not_to include(ore.ore_id)
    end

    it 'returns false for ore not in crucible' do
      result = crucible.unload_ore('nonexistent')
      expect(result[:unloaded]).to be false
    end
  end

  describe '#smelt!' do
    context 'when temperature is below threshold' do
      it 'returns smelted: false' do
        ore = make_ore
        crucible.load_ore(ore.ore_id)
        result = crucible.smelt!(ore_store)
        expect(result[:smelted]).to be false
        expect(result[:reason]).to eq(:temperature_too_low)
      end
    end

    context 'when no ores loaded' do
      it 'returns smelted: false' do
        c = described_class.new(temperature: 0.7)
        result = c.smelt!(ore_store)
        expect(result[:smelted]).to be false
        expect(result[:reason]).to eq(:no_ores)
      end
    end

    context 'when temperature is sufficient and ores loaded' do
      let(:hot_crucible) { described_class.new(temperature: 0.7) }

      it 'returns smelted: true' do
        ore = make_ore
        hot_crucible.load_ore(ore.ore_id)
        result = hot_crucible.smelt!(ore_store)
        expect(result[:smelted]).to be true
      end

      it 'produces an alloy with expected fields' do
        ore = make_ore
        hot_crucible.load_ore(ore.ore_id)
        result = hot_crucible.smelt!(ore_store)
        alloy = result[:alloy]
        expect(alloy).to include(:alloy_id, :alloy_type, :domain, :purity, :ore_count)
      end

      it 'clears ore_ids after smelting' do
        ore = make_ore
        hot_crucible.load_ore(ore.ore_id)
        hot_crucible.smelt!(ore_store)
        expect(hot_crucible.ore_ids).to be_empty
      end

      it 'records source ore ids in alloy' do
        ore = make_ore
        ore_id = ore.ore_id
        hot_crucible.load_ore(ore_id)
        result = hot_crucible.smelt!(ore_store)
        expect(result[:alloy][:source_ore_ids]).to include(ore_id)
      end

      it 'infers alloy type from experience ores' do
        ore = make_ore(type: :experience)
        hot_crucible.load_ore(ore.ore_id)
        result = hot_crucible.smelt!(ore_store)
        expect(result[:alloy][:alloy_type]).to eq(:wisdom)
      end

      it 'infers alloy type from hypothesis ores' do
        ore = make_ore(type: :hypothesis)
        hot_crucible.load_ore(ore.ore_id)
        result = hot_crucible.smelt!(ore_store)
        expect(result[:alloy][:alloy_type]).to eq(:theory)
      end

      it 'accepts explicit alloy_type override' do
        ore = make_ore
        hot_crucible.load_ore(ore.ore_id)
        result = hot_crucible.smelt!(ore_store, alloy_type: :synthesis)
        expect(result[:alloy][:alloy_type]).to eq(:synthesis)
      end

      it 'applies temperature bonus to purity' do
        # At temp 0.7, bonus = 0.7 - 0.6 = 0.1 * 0.2 = 0.02
        ore = make_ore(purity: 0.7)
        hot_crucible.load_ore(ore.ore_id)
        result = hot_crucible.smelt!(ore_store)
        expect(result[:alloy][:purity]).to be > 0.7
      end
    end
  end

  describe '#overheated?' do
    it 'returns false below threshold' do
      expect(crucible.overheated?).to be false
    end

    it 'returns true at or above DESTROY_THRESHOLD' do
      c = described_class.new(temperature: 0.95)
      expect(c.overheated?).to be true
    end
  end

  describe '#optimal?' do
    it 'returns false below smelt threshold' do
      expect(crucible.optimal?).to be false
    end

    it 'returns true in optimal range' do
      c = described_class.new(temperature: 0.7)
      expect(c.optimal?).to be true
    end

    it 'returns false when overheated' do
      c = described_class.new(temperature: 0.97)
      expect(c.optimal?).to be false
    end
  end

  describe '#temperature_label' do
    it 'returns :cold for cold crucible' do
      expect(crucible.temperature_label).to eq(:cold)
    end

    it 'returns :white_hot for very hot crucible' do
      c = described_class.new(temperature: 0.95)
      expect(c.temperature_label).to eq(:white_hot)
    end

    it 'returns :warm for mid-range temperature' do
      c = described_class.new(temperature: 0.6)
      expect(c.temperature_label).to eq(:warm)
    end
  end

  describe '#full?' do
    it 'returns false when not at capacity' do
      expect(crucible.full?).to be false
    end

    it 'returns true when at capacity' do
      c = described_class.new(capacity: 1)
      ore = make_ore
      c.load_ore(ore.ore_id)
      expect(c.full?).to be true
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      h = crucible.to_h
      expect(h).to include(:crucible_id, :temperature, :capacity, :ore_count, :ore_ids,
                           :overheated, :optimal, :temperature_label, :created_at)
    end

    it 'reflects current state' do
      crucible.heat!(0.3)
      ore = make_ore
      crucible.load_ore(ore.ore_id)
      h = crucible.to_h
      expect(h[:ore_count]).to eq(1)
      expect(h[:temperature]).to be_within(0.001).of(0.3)
    end
  end
end
