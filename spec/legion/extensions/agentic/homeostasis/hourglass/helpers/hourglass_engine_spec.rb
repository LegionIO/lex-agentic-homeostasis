# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::HourglassEngine do
  let(:engine) { described_class.new }

  def add_hourglass(eng = engine, grain_type: :attention, top_level: 1.0, neck_width: 0.5)
    eng.create_hourglass(grain_type: grain_type, top_level: top_level, neck_width: neck_width)
  end

  def add_grain(eng = engine, grain_type: :attention, weight: 0.8)
    eng.create_grain(grain_type: grain_type, weight: weight)
  end

  describe '#initialize' do
    it 'starts with no hourglasses' do
      expect(engine.hourglasses).to be_empty
    end

    it 'starts with no grains' do
      expect(engine.grains).to be_empty
    end
  end

  describe '#create_grain' do
    it 'returns a Grain instance' do
      grain = add_grain
      expect(grain).to be_a(Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Grain)
    end

    it 'registers the grain by id' do
      grain = add_grain
      expect(engine.grains[grain.id]).to equal(grain)
    end

    it 'increments grain count' do
      add_grain
      add_grain
      expect(engine.grains.size).to eq(2)
    end

    it 'raises ArgumentError when MAX_GRAINS is reached' do
      max = Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Constants::MAX_GRAINS
      max.times { |i| engine.create_grain(grain_type: %i[attention focus patience willpower creativity][i % 5]) }
      expect { engine.create_grain(grain_type: :attention) }
        .to raise_error(ArgumentError, /MAX_GRAINS/)
    end

    it 'accepts domain and content' do
      grain = engine.create_grain(grain_type: :focus, domain: 'work', content: 'deep task', weight: 0.7)
      expect(grain.domain).to eq('work')
      expect(grain.content).to eq('deep task')
    end
  end

  describe '#create_hourglass' do
    it 'returns an Hourglass instance' do
      h = add_hourglass
      expect(h).to be_a(Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Hourglass)
    end

    it 'registers the hourglass by id' do
      h = add_hourglass
      expect(engine.hourglasses[h.id]).to equal(h)
    end

    it 'increments hourglass count' do
      add_hourglass
      add_hourglass
      expect(engine.hourglasses.size).to eq(2)
    end

    it 'raises ArgumentError when MAX_HOURGLASSES is reached' do
      max = Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Constants::MAX_HOURGLASSES
      max.times { engine.create_hourglass(grain_type: :attention) }
      expect { engine.create_hourglass(grain_type: :attention) }
        .to raise_error(ArgumentError, /MAX_HOURGLASSES/)
    end

    it 'sets domain on the hourglass' do
      h = engine.create_hourglass(grain_type: :focus, domain: 'planning')
      expect(h.domain).to eq('planning')
    end
  end

  describe '#flow_tick' do
    it 'returns a result hash with expected keys' do
      add_hourglass
      result = engine.flow_tick
      expect(result.keys).to include(:ticked, :expired, :blocked, :total)
    end

    it 'returns total matching hourglass count' do
      add_hourglass
      add_hourglass
      result = engine.flow_tick
      expect(result[:total]).to eq(2)
    end

    it 'returns 0 counts for empty engine' do
      result = engine.flow_tick
      expect(result[:ticked]).to eq(0)
      expect(result[:expired]).to eq(0)
      expect(result[:blocked]).to eq(0)
    end

    it 'counts expired hourglasses separately' do
      engine.create_hourglass(grain_type: :attention, top_level: 0.0, bottom_level: 0.8)
      result = engine.flow_tick
      expect(result[:expired]).to eq(1)
      expect(result[:ticked]).to eq(0)
    end

    it 'counts paused hourglasses as blocked' do
      h = add_hourglass
      h.pause!
      result = engine.flow_tick
      expect(result[:blocked]).to eq(1)
    end

    it 'advances non-expired hourglasses' do
      allow_any_instance_of(Object).to receive(:rand).and_return(0.99)
      h = add_hourglass(top_level: 1.0, neck_width: 0.5)
      initial_top = h.top_level
      engine.flow_tick
      expect(h.top_level).to be < initial_top
    end

    it 'accepts custom rate' do
      result = engine.flow_tick(0.1)
      expect(result).to be_a(Hash)
    end

    it 'skips paused hourglasses in tick count' do
      h = add_hourglass
      h.pause!
      result = engine.flow_tick
      expect(result[:ticked]).to eq(0)
    end
  end

  describe '#flip' do
    it 'flips the hourglass and returns it' do
      h = add_hourglass
      result = engine.flip(h.id)
      expect(result).to equal(h)
    end

    it 'sets flipped_at on the hourglass' do
      h = add_hourglass
      engine.flip(h.id)
      expect(h.flipped_at).to be_a(Time)
    end

    it 'raises ArgumentError for unknown hourglass_id' do
      expect { engine.flip('nonexistent-id') }.to raise_error(ArgumentError, /not found/)
    end

    it 'swaps top and bottom levels' do
      h = engine.create_hourglass(grain_type: :attention, top_level: 0.3, bottom_level: 0.7)
      engine.flip(h.id)
      expect(h.top_level).to be_within(0.001).of(0.7)
      expect(h.bottom_level).to be_within(0.001).of(0.3)
    end
  end

  describe '#most_urgent' do
    it 'returns nil when no hourglasses' do
      expect(engine.most_urgent).to be_nil
    end

    it 'returns the hourglass with the lowest top_level' do
      h1 = engine.create_hourglass(grain_type: :attention, top_level: 0.8)
      h2 = engine.create_hourglass(grain_type: :focus,     top_level: 0.2)
      engine.create_hourglass(grain_type: :patience, top_level: 0.5)
      expect(engine.most_urgent.id).to eq(h2.id)
      expect(engine.most_urgent.id).not_to eq(h1.id)
    end

    it 'excludes expired hourglasses' do
      engine.create_hourglass(grain_type: :attention, top_level: 0.0, bottom_level: 0.9)
      h2 = engine.create_hourglass(grain_type: :focus, top_level: 0.3)
      expect(engine.most_urgent.id).to eq(h2.id)
    end

    it 'excludes paused hourglasses' do
      h1 = engine.create_hourglass(grain_type: :attention, top_level: 0.1)
      h1.pause!
      h2 = engine.create_hourglass(grain_type: :focus, top_level: 0.3)
      expect(engine.most_urgent.id).to eq(h2.id)
    end
  end

  describe '#most_depleted' do
    it 'returns nil when no hourglasses' do
      expect(engine.most_depleted).to be_nil
    end

    it 'returns the hourglass with the highest bottom_level' do
      engine.create_hourglass(grain_type: :attention, bottom_level: 0.2)
      h2 = engine.create_hourglass(grain_type: :focus, bottom_level: 0.8)
      expect(engine.most_depleted.id).to eq(h2.id)
    end
  end

  describe '#flow_report' do
    it 'returns a hash with expected keys' do
      add_hourglass
      report = engine.flow_report
      expect(report.keys).to include(:total, :grain_count, :flowing, :blocked, :empty, :full, :paused,
                                     :most_urgent, :most_depleted, :hourglasses)
    end

    it 'total matches hourglass count' do
      add_hourglass
      add_hourglass
      expect(engine.flow_report[:total]).to eq(2)
    end

    it 'grain_count matches grain registry' do
      add_grain
      add_grain
      expect(engine.flow_report[:grain_count]).to eq(2)
    end

    it 'hourglasses is an array of hashes' do
      add_hourglass
      report = engine.flow_report
      expect(report[:hourglasses]).to be_an(Array)
      expect(report[:hourglasses].first).to be_a(Hash)
    end

    it 'most_urgent is nil when all expired' do
      engine.create_hourglass(grain_type: :attention, top_level: 0.0, bottom_level: 1.0)
      report = engine.flow_report
      expect(report[:most_urgent]).to be_nil
    end

    it 'most_depleted is a hash when hourglasses exist' do
      add_hourglass
      report = engine.flow_report
      expect(report[:most_depleted]).to be_a(Hash)
    end

    it 'counts states correctly' do
      engine.create_hourglass(grain_type: :attention, top_level: 0.0, bottom_level: 0.8)
      engine.create_hourglass(grain_type: :focus, top_level: 0.5, neck_width: 0.5)
      report = engine.flow_report
      expect(report[:empty]).to eq(1)
      expect(report[:flowing]).to eq(1)
    end
  end
end
