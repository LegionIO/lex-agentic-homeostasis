# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Hourglass::Runners::CognitiveHourglass do
  let(:engine) { Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::HourglassEngine.new }

  subject(:runner) { described_class }

  describe '.create_grain' do
    it 'returns success: true with a grain hash' do
      result = runner.create_grain(grain_type: :attention, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:grain]).to be_a(Hash)
    end

    it 'registers the grain in the engine' do
      runner.create_grain(grain_type: :focus, engine: engine)
      expect(engine.grains.size).to eq(1)
    end

    it 'accepts all valid grain_types' do
      Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Constants::GRAIN_TYPES.each do |type|
        result = runner.create_grain(grain_type: type, engine: engine)
        expect(result[:success]).to be(true)
      end
    end

    it 'returns success: false for invalid grain_type' do
      result = runner.create_grain(grain_type: :invalid, engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to be_a(String)
    end

    it 'accepts domain and content kwargs' do
      result = runner.create_grain(grain_type: :focus, domain: 'work', content: 'task', engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:grain][:domain]).to eq('work')
    end

    it 'accepts weight kwarg' do
      result = runner.create_grain(grain_type: :focus, weight: 0.5, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:grain][:weight]).to eq(0.5)
    end

    it 'accepts ** splat without error' do
      result = runner.create_grain(grain_type: :attention, extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '.create_hourglass' do
    it 'returns success: true with an hourglass hash' do
      result = runner.create_hourglass(grain_type: :attention, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:hourglass]).to be_a(Hash)
    end

    it 'registers the hourglass in the engine' do
      runner.create_hourglass(grain_type: :focus, engine: engine)
      expect(engine.hourglasses.size).to eq(1)
    end

    it 'accepts all valid grain_types' do
      Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Constants::GRAIN_TYPES.each do |type|
        result = runner.create_hourglass(grain_type: type, engine: engine)
        expect(result[:success]).to be(true)
      end
    end

    it 'returns success: false for invalid grain_type' do
      result = runner.create_hourglass(grain_type: :invalid, engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to be_a(String)
    end

    it 'accepts top_level kwarg' do
      result = runner.create_hourglass(grain_type: :attention, top_level: 0.7, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:hourglass][:top_level]).to be_within(0.001).of(0.7)
    end

    it 'accepts neck_width kwarg' do
      result = runner.create_hourglass(grain_type: :attention, neck_width: 0.2, engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:hourglass][:neck_width]).to be_within(0.001).of(0.2)
    end

    it 'accepts domain kwarg' do
      result = runner.create_hourglass(grain_type: :focus, domain: 'planning', engine: engine)
      expect(result[:success]).to be(true)
      expect(result[:hourglass][:domain]).to eq('planning')
    end

    it 'accepts ** splat without error' do
      result = runner.create_hourglass(grain_type: :attention, extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '.flow_tick' do
    before { runner.create_hourglass(grain_type: :attention, engine: engine) }

    it 'returns success: true' do
      result = runner.flow_tick(engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns tick result fields' do
      result = runner.flow_tick(engine: engine)
      expect(result.keys).to include(:ticked, :expired, :blocked, :total)
    end

    it 'returns total matching registered hourglasses' do
      result = runner.flow_tick(engine: engine)
      expect(result[:total]).to eq(1)
    end

    it 'accepts custom rate kwarg' do
      result = runner.flow_tick(rate: 0.1, engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'accepts ** splat without error' do
      result = runner.flow_tick(extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'works with an empty engine' do
      empty = Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::HourglassEngine.new
      result = runner.flow_tick(engine: empty)
      expect(result[:success]).to be(true)
      expect(result[:total]).to eq(0)
    end
  end

  describe '.flip' do
    let!(:hourglass) do
      runner.create_hourglass(grain_type: :attention, engine: engine)[:hourglass]
    end

    it 'returns success: true' do
      result = runner.flip(hourglass_id: hourglass[:id], engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns updated hourglass hash' do
      result = runner.flip(hourglass_id: hourglass[:id], engine: engine)
      expect(result[:hourglass]).to be_a(Hash)
      expect(result[:hourglass][:flipped_at]).not_to be_nil
    end

    it 'returns success: false for unknown id' do
      result = runner.flip(hourglass_id: 'nonexistent-id', engine: engine)
      expect(result[:success]).to be(false)
      expect(result[:error]).to be_a(String)
    end

    it 'accepts ** splat without error' do
      result = runner.flip(hourglass_id: hourglass[:id], extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'swaps top and bottom on the engine hourglass' do
      h_obj = engine.create_hourglass(grain_type: :patience, top_level: 0.3, bottom_level: 0.6)
      result = runner.flip(hourglass_id: h_obj.id, engine: engine)
      expect(result[:hourglass][:top_level]).to be_within(0.001).of(0.6)
    end
  end

  describe '.list_hourglasses' do
    it 'returns success: true' do
      result = runner.list_hourglasses(engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns empty array when no hourglasses' do
      result = runner.list_hourglasses(engine: engine)
      expect(result[:hourglasses]).to eq([])
      expect(result[:count]).to eq(0)
    end

    it 'returns all registered hourglasses' do
      runner.create_hourglass(grain_type: :attention, engine: engine)
      runner.create_hourglass(grain_type: :focus, engine: engine)
      result = runner.list_hourglasses(engine: engine)
      expect(result[:hourglasses].size).to eq(2)
      expect(result[:count]).to eq(2)
    end

    it 'each hourglass is a hash' do
      runner.create_hourglass(grain_type: :attention, engine: engine)
      result = runner.list_hourglasses(engine: engine)
      expect(result[:hourglasses].first).to be_a(Hash)
    end

    it 'accepts ** splat without error' do
      result = runner.list_hourglasses(extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end

  describe '.time_status' do
    before { runner.create_hourglass(grain_type: :attention, engine: engine) }

    it 'returns success: true' do
      result = runner.time_status(engine: engine)
      expect(result[:success]).to be(true)
    end

    it 'returns flow report fields' do
      result = runner.time_status(engine: engine)
      expect(result.keys).to include(:total, :flowing, :empty, :paused, :blocked, :full, :grain_count)
    end

    it 'total matches registered hourglass count' do
      runner.create_hourglass(grain_type: :focus, engine: engine)
      result = runner.time_status(engine: engine)
      expect(result[:total]).to eq(2)
    end

    it 'works with an empty engine' do
      empty = Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::HourglassEngine.new
      result = runner.time_status(engine: empty)
      expect(result[:success]).to be(true)
      expect(result[:total]).to eq(0)
    end

    it 'accepts ** splat without error' do
      result = runner.time_status(extra: 'ignored', engine: engine)
      expect(result[:success]).to be(true)
    end
  end
end
