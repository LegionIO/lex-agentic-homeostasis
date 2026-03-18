# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weather::Runners::CognitiveWeather do
  let(:engine) { Legion::Extensions::Agentic::Homeostasis::Weather::Helpers::WeatherEngine.new }

  describe '#create_front' do
    it 'returns success: true with valid args' do
      result = described_class.create_front(front_type: :warm, domain: 'planning', engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes the front hash in result' do
      result = described_class.create_front(front_type: :cold, domain: 'analysis', engine: engine)
      expect(result[:front]).to be_a(Hash)
      expect(result[:front][:front_type]).to eq(:cold)
    end

    it 'returns success: false for unknown front_type' do
      result = described_class.create_front(front_type: :plasma, domain: 'x', engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/unknown front_type/)
    end

    it 'accepts pressure, temperature, humidity' do
      result = described_class.create_front(front_type: :warm, domain: 'x',
                                            pressure: 0.7, temperature: 0.4, humidity: 0.6,
                                            engine: engine)
      expect(result[:front][:pressure]).to eq(0.7)
    end

    it 'returns max_fronts_reached when engine is at capacity' do
      allow(engine).to receive(:create_front).and_return(nil)
      result = described_class.create_front(front_type: :warm, domain: 'x', engine: engine)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:max_fronts_reached)
    end
  end

  describe '#brew_storm' do
    let(:front) do
      described_class.create_front(front_type: :cold, domain: 'x', engine: engine)[:front]
    end

    it 'returns success: true with valid front_id' do
      result = described_class.brew_storm(front_id: front[:id], engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes the storm hash in result' do
      result = described_class.brew_storm(front_id: front[:id], condition: :foggy, engine: engine)
      expect(result[:storm]).to be_a(Hash)
      expect(result[:storm][:condition]).to eq(:foggy)
    end

    it 'returns brew_failed for unknown front_id' do
      result = described_class.brew_storm(front_id: 'bad-id', engine: engine)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:brew_failed)
    end

    it 'returns error for unknown condition' do
      result = described_class.brew_storm(front_id: front[:id], condition: :tornado, engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/unknown condition/)
    end

    it 'passes intensity and coverage' do
      result = described_class.brew_storm(front_id: front[:id], intensity: 0.8,
                                          coverage: 0.6, engine: engine)
      expect(result[:storm][:intensity]).to be_within(0.001).of(0.8)
    end
  end

  describe '#intensify' do
    let(:front) do
      described_class.create_front(front_type: :warm, domain: 'x', engine: engine)[:front]
    end
    let(:storm) do
      described_class.brew_storm(front_id: front[:id], intensity: 0.4, engine: engine)[:storm]
    end

    it 'returns success: true for valid storm_id' do
      result = described_class.intensify(storm_id: storm[:id], engine: engine)
      expect(result[:success]).to be true
    end

    it 'increases storm intensity' do
      result = described_class.intensify(storm_id: storm[:id], engine: engine)
      expect(result[:storm][:intensity]).to be > storm[:intensity]
    end

    it 'returns storm_not_found for unknown storm_id' do
      result = described_class.intensify(storm_id: 'unknown', engine: engine)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:storm_not_found)
    end

    it 'accepts a custom rate' do
      result = described_class.intensify(storm_id: storm[:id], rate: 0.2, engine: engine)
      expect(result[:storm][:intensity]).to be_within(0.001).of(0.6)
    end
  end

  describe '#forecast' do
    it 'returns success: true' do
      result = described_class.forecast(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns clear with no storms' do
      result = described_class.forecast(engine: engine)
      expect(result[:condition]).to eq(:clear)
    end

    it 'reflects active storms in the forecast' do
      described_class.create_front(front_type: :cold, domain: 'x', engine: engine).tap do |r|
        described_class.brew_storm(front_id: r[:front][:id], condition: :stormy, engine: engine)
      end
      result = described_class.forecast(engine: engine)
      expect(result[:active_storms]).to eq(1)
    end
  end

  describe '#list_fronts' do
    it 'returns success: true' do
      result = described_class.list_fronts(engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns empty fronts for a fresh engine' do
      result = described_class.list_fronts(engine: engine)
      expect(result[:fronts]).to eq([])
      expect(result[:count]).to eq(0)
    end

    it 'reflects created fronts' do
      described_class.create_front(front_type: :warm, domain: 'test', engine: engine)
      result = described_class.list_fronts(engine: engine)
      expect(result[:count]).to eq(1)
    end

    it 'returns fronts as array of hashes' do
      described_class.create_front(front_type: :cold, domain: 'a', engine: engine)
      result = described_class.list_fronts(engine: engine)
      expect(result[:fronts].first).to be_a(Hash)
    end
  end

  describe '#weather_status' do
    it 'returns success: true' do
      result = described_class.weather_status(engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes front_count and storm_count' do
      result = described_class.weather_status(engine: engine)
      expect(result).to have_key(:front_count)
      expect(result).to have_key(:storm_count)
    end

    it 'includes fronts and storms arrays' do
      result = described_class.weather_status(engine: engine)
      expect(result[:fronts]).to be_an(Array)
      expect(result[:storms]).to be_an(Array)
    end

    it 'reflects created fronts and storms' do
      r = described_class.create_front(front_type: :warm, domain: 'z', engine: engine)
      described_class.brew_storm(front_id: r[:front][:id], engine: engine)
      status = described_class.weather_status(engine: engine)
      expect(status[:front_count]).to eq(1)
      expect(status[:storm_count]).to eq(1)
    end
  end
end
