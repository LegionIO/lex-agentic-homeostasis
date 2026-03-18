# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Core::Helpers::AllostaticLoad do
  subject(:allostatic) { described_class.new }

  let(:regulator) { Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Regulator.new }

  describe '#initialize' do
    it 'starts at zero load' do
      expect(allostatic.load).to eq(0.0)
    end

    it 'starts with empty history' do
      expect(allostatic.history).to be_empty
    end
  end

  describe '#update' do
    it 'increases load when subsystems deviate' do
      regulator.regulate(emotional_arousal: 1.0, curiosity_intensity: 1.0)
      allostatic.update(regulator)
      expect(allostatic.load).to be > 0.0
    end

    it 'decreases load when subsystems are in tolerance' do
      # First create some load
      regulator.regulate(emotional_arousal: 1.0)
      3.times { allostatic.update(regulator) }
      elevated_load = allostatic.load

      # Now bring everything back to normal
      targets = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants::SETPOINTS.transform_values { |c| c[:target] }
      regulator.regulate(targets)
      allostatic.update(regulator)

      expect(allostatic.load).to be < elevated_load
    end

    it 'records history' do
      regulator.regulate(emotional_arousal: 0.5)
      allostatic.update(regulator)
      expect(allostatic.history.size).to eq(1)
    end

    it 'tracks peak load' do
      regulator.regulate(emotional_arousal: 1.0, curiosity_intensity: 1.0)
      3.times { allostatic.update(regulator) }
      peak = allostatic.peak_load

      targets = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants::SETPOINTS.transform_values { |c| c[:target] }
      regulator.regulate(targets)
      allostatic.update(regulator)

      expect(allostatic.peak_load).to eq(peak)
    end

    it 'clamps load to 0-1 range' do
      regulator.regulate(emotional_arousal: 1.0, curiosity_intensity: 1.0, cognitive_load: 1.0)
      50.times { allostatic.update(regulator) }
      expect(allostatic.load).to be <= 1.0
    end
  end

  describe '#classification' do
    it 'returns :healthy at zero load' do
      expect(allostatic.classification).to eq(:healthy)
    end

    it 'returns :elevated after moderate deviation' do
      regulator.regulate(emotional_arousal: 1.0, curiosity_intensity: 1.0)
      15.times { allostatic.update(regulator) }
      expect(%i[elevated high critical]).to include(allostatic.classification)
    end
  end

  describe '#recovering?' do
    it 'returns false with insufficient data' do
      expect(allostatic.recovering?).to be false
    end

    it 'detects recovery after load reduction' do
      regulator.regulate(emotional_arousal: 1.0)
      5.times { allostatic.update(regulator) }

      targets = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants::SETPOINTS.transform_values { |c| c[:target] }
      regulator.regulate(targets)
      5.times { allostatic.update(regulator) }

      expect(allostatic.recovering?).to be true
    end
  end

  describe '#trend' do
    it 'returns :insufficient_data with few observations' do
      expect(allostatic.trend).to eq(:insufficient_data)
    end
  end

  describe '#reset' do
    it 'clears load and history' do
      regulator.regulate(emotional_arousal: 1.0)
      allostatic.update(regulator)
      allostatic.reset
      expect(allostatic.load).to eq(0.0)
      expect(allostatic.history).to be_empty
    end
  end

  describe '#to_h' do
    it 'returns a complete status hash' do
      h = allostatic.to_h
      expect(h).to include(:load, :peak_load, :classification, :recovering, :trend, :history_size)
    end
  end
end
