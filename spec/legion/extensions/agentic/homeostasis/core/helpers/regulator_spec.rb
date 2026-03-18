# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Regulator do
  subject(:regulator) { described_class.new }

  describe '#initialize' do
    it 'creates setpoints for all configured subsystems' do
      expect(regulator.setpoints.size).to eq(7)
    end

    it 'starts with empty signals' do
      expect(regulator.signals).to be_empty
    end
  end

  describe '#regulate' do
    it 'produces signals for provided observations' do
      signals = regulator.regulate(emotional_arousal: 0.8, curiosity_intensity: 0.9)
      expect(signals).to have_key(:emotional_arousal)
      expect(signals).to have_key(:curiosity_intensity)
    end

    it 'generates dampen signal when value is above setpoint' do
      signals = regulator.regulate(emotional_arousal: 0.9)
      expect(signals[:emotional_arousal][:type]).to eq(:dampen)
    end

    it 'generates amplify signal when value is below setpoint' do
      signals = regulator.regulate(emotional_arousal: 0.05)
      expect(signals[:emotional_arousal][:type]).to eq(:amplify)
    end

    it 'generates hold signal when value is at setpoint' do
      target = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants::SETPOINTS[:emotional_arousal][:target]
      signals = regulator.regulate(emotional_arousal: target)
      expect(signals[:emotional_arousal][:type]).to eq(:hold)
    end

    it 'increments regulation count' do
      regulator.regulate(emotional_arousal: 0.5)
      expect(regulator.regulation_count).to eq(1)
    end

    it 'ignores unknown subsystems' do
      signals = regulator.regulate(nonexistent_system: 0.5)
      expect(signals).to be_empty
    end
  end

  describe '#regulation_health' do
    it 'returns 1.0 when all subsystems are at target' do
      targets = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants::SETPOINTS.transform_values { |c| c[:target] }
      regulator.regulate(targets)
      expect(regulator.regulation_health).to eq(1.0)
    end

    it 'returns lower health when subsystems deviate' do
      regulator.regulate(emotional_arousal: 1.0, curiosity_intensity: 1.0, cognitive_load: 1.0)
      expect(regulator.regulation_health).to be < 1.0
    end
  end

  describe '#health_label' do
    it 'returns :stable when all is well' do
      targets = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants::SETPOINTS.transform_values { |c| c[:target] }
      regulator.regulate(targets)
      expect(regulator.health_label).to eq(:stable)
    end
  end

  describe '#worst_deviation' do
    it 'identifies the most deviated subsystem' do
      regulator.regulate(emotional_arousal: 1.0, curiosity_intensity: 0.5)
      worst = regulator.worst_deviation
      expect(worst[:subsystem]).to eq(:emotional_arousal)
    end
  end

  describe '#subsystem_status' do
    it 'returns nil for unknown subsystem' do
      expect(regulator.subsystem_status(:nonexistent)).to be_nil
    end

    it 'returns status for known subsystem' do
      regulator.regulate(emotional_arousal: 0.7)
      status = regulator.subsystem_status(:emotional_arousal)
      expect(status).to include(:name, :target, :tolerance, :signal)
    end
  end

  describe '#adapt_setpoints' do
    it 'adapts targets for in-tolerance setpoints' do
      targets = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants::SETPOINTS.transform_values { |c| c[:target] + 0.1 }
      regulator.regulate(targets)
      original_target = regulator.setpoints[:emotional_arousal].target
      regulator.adapt_setpoints
      expect(regulator.setpoints[:emotional_arousal].target).not_to eq(original_target)
    end
  end

  describe '#to_h' do
    it 'returns a complete state hash' do
      h = regulator.to_h
      expect(h).to include(:setpoints, :signals, :regulation_count, :health, :health_label)
    end
  end
end
