# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weather::Helpers::WeatherEngine do
  subject(:engine) { described_class.new }

  describe '#create_front' do
    it 'returns a Front instance' do
      front = engine.create_front(front_type: :warm, domain: 'planning')
      expect(front).to be_a(Legion::Extensions::Agentic::Homeostasis::Weather::Helpers::Front)
    end

    it 'adds front to the fronts collection' do
      expect { engine.create_front(front_type: :cold, domain: 'analysis') }.to change(engine.fronts, :size).by(1)
    end

    it 'passes pressure to the front' do
      front = engine.create_front(front_type: :warm, domain: 'x', pressure: 0.8)
      expect(front.pressure).to eq(0.8)
    end

    it 'passes temperature and humidity' do
      front = engine.create_front(front_type: :cold, domain: 'x', temperature: 0.3, humidity: 0.7)
      expect(front.temperature).to eq(0.3)
      expect(front.humidity).to eq(0.7)
    end

    it 'returns nil when MAX_FRONTS is reached' do
      engine.instance_variable_set(:@fronts, Array.new(100))
      result = engine.create_front(front_type: :warm, domain: 'x')
      expect(result).to be_nil
    end
  end

  describe '#brew_storm' do
    let(:front) { engine.create_front(front_type: :warm, domain: 'planning') }

    it 'returns a Storm instance' do
      storm = engine.brew_storm(front_id: front.id)
      expect(storm).to be_a(Legion::Extensions::Agentic::Homeostasis::Weather::Helpers::Storm)
    end

    it 'adds storm to the storms collection' do
      expect { engine.brew_storm(front_id: front.id) }.to change(engine.storms, :size).by(1)
    end

    it 'links storm to the front_id' do
      storm = engine.brew_storm(front_id: front.id)
      expect(storm.front_ids).to include(front.id)
    end

    it 'sets condition on the storm' do
      storm = engine.brew_storm(front_id: front.id, condition: :foggy)
      expect(storm.condition).to eq(:foggy)
    end

    it 'returns nil for unknown front_id' do
      result = engine.brew_storm(front_id: 'nonexistent-uuid')
      expect(result).to be_nil
    end

    it 'returns nil when MAX_STORMS is reached' do
      engine.instance_variable_set(:@storms, Array.new(50))
      result = engine.brew_storm(front_id: front.id)
      expect(result).to be_nil
    end
  end

  describe '#intensify_storm' do
    let(:front) { engine.create_front(front_type: :cold, domain: 'x') }
    let(:storm) { engine.brew_storm(front_id: front.id, intensity: 0.5) }

    it 'increases storm intensity' do
      initial = storm.intensity
      engine.intensify_storm(storm_id: storm.id)
      expect(storm.intensity).to be > initial
    end

    it 'returns the storm' do
      result = engine.intensify_storm(storm_id: storm.id)
      expect(result).to eq(storm)
    end

    it 'returns nil for unknown storm_id' do
      result = engine.intensify_storm(storm_id: 'bad-id')
      expect(result).to be_nil
    end

    it 'accepts a custom rate' do
      engine.intensify_storm(storm_id: storm.id, rate: 0.2)
      expect(storm.intensity).to be_within(0.001).of(0.7)
    end
  end

  describe '#dissipate_all!' do
    it 'dissipates all storms' do
      front = engine.create_front(front_type: :warm, domain: 'x')
      storm = engine.brew_storm(front_id: front.id, intensity: 0.8)
      initial = storm.intensity
      engine.dissipate_all!
      expect(storm.intensity).to be < initial
    end

    it 'returns the storm count' do
      front = engine.create_front(front_type: :warm, domain: 'x')
      engine.brew_storm(front_id: front.id)
      engine.brew_storm(front_id: front.id, condition: :foggy)
      expect(engine.dissipate_all!).to eq(2)
    end

    it 'returns 0 with no storms' do
      expect(engine.dissipate_all!).to eq(0)
    end
  end

  describe '#weather_forecast' do
    it 'returns clear condition with no storms' do
      forecast = engine.weather_forecast
      expect(forecast[:condition]).to eq(:clear)
      expect(forecast[:active_storms]).to eq(0)
      expect(forecast[:avg_intensity]).to eq(0.0)
    end

    it 'returns dominant storm condition when storms exist' do
      front = engine.create_front(front_type: :cold, domain: 'x')
      engine.brew_storm(front_id: front.id, condition: :blizzard, intensity: 0.9)
      forecast = engine.weather_forecast
      expect(forecast[:condition]).to eq(:blizzard)
    end

    it 'includes avg_intensity' do
      front = engine.create_front(front_type: :warm, domain: 'x')
      engine.brew_storm(front_id: front.id, intensity: 0.6)
      engine.brew_storm(front_id: front.id, intensity: 0.4)
      forecast = engine.weather_forecast
      expect(forecast[:avg_intensity]).to be_within(0.001).of(0.5)
    end

    it 'includes active_storms count' do
      front = engine.create_front(front_type: :warm, domain: 'x')
      engine.brew_storm(front_id: front.id)
      expect(engine.weather_forecast[:active_storms]).to eq(1)
    end

    it 'includes clarity_label' do
      front = engine.create_front(front_type: :warm, domain: 'x')
      engine.brew_storm(front_id: front.id, intensity: 1.0)
      expect(engine.weather_forecast[:clarity_label]).to eq('opaque')
    end
  end

  describe '#most_severe' do
    it 'returns nil with no fronts' do
      expect(engine.most_severe).to be_nil
    end

    it 'returns the front with highest pressure' do
      engine.create_front(front_type: :warm, domain: 'a', pressure: 0.3)
      high = engine.create_front(front_type: :cold, domain: 'b', pressure: 0.9)
      engine.create_front(front_type: :occluded, domain: 'c', pressure: 0.6)
      expect(engine.most_severe).to eq(high)
    end
  end

  describe '#calmest' do
    it 'returns nil with no fronts' do
      expect(engine.calmest).to be_nil
    end

    it 'returns the front with lowest pressure' do
      calm = engine.create_front(front_type: :stationary, domain: 'a', pressure: 0.1)
      engine.create_front(front_type: :warm, domain: 'b', pressure: 0.7)
      expect(engine.calmest).to eq(calm)
    end
  end

  describe '#atmospheric_report' do
    it 'includes front_count and storm_count' do
      report = engine.atmospheric_report
      expect(report).to have_key(:front_count)
      expect(report).to have_key(:storm_count)
    end

    it 'includes fronts and storms arrays' do
      report = engine.atmospheric_report
      expect(report[:fronts]).to be_an(Array)
      expect(report[:storms]).to be_an(Array)
    end

    it 'includes forecast' do
      report = engine.atmospheric_report
      expect(report).to have_key(:forecast)
    end

    it 'includes most_severe and calmest' do
      report = engine.atmospheric_report
      expect(report).to have_key(:most_severe)
      expect(report).to have_key(:calmest)
    end

    it 'reflects current state' do
      engine.create_front(front_type: :warm, domain: 'x')
      report = engine.atmospheric_report
      expect(report[:front_count]).to eq(1)
    end
  end
end
