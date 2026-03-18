# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Constants do
  describe 'SETPOINTS' do
    it 'defines 7 regulated subsystems' do
      expect(described_class::SETPOINTS.size).to eq(7)
    end

    it 'has target and tolerance for each setpoint' do
      described_class::SETPOINTS.each_value do |config|
        expect(config).to have_key(:target)
        expect(config).to have_key(:tolerance)
        expect(config[:target]).to be_between(0.0, 1.0)
        expect(config[:tolerance]).to be_between(0.0, 1.0)
      end
    end
  end

  describe 'REGULATION_GAIN' do
    it 'has a gain for every setpoint' do
      described_class::SETPOINTS.each_key do |subsystem|
        expect(described_class::REGULATION_GAIN).to have_key(subsystem)
      end
    end

    it 'has gains between 0 and 1' do
      described_class::REGULATION_GAIN.each_value do |gain|
        expect(gain).to be_between(0.0, 1.0)
      end
    end
  end

  describe 'allostatic load thresholds' do
    it 'defines ordered thresholds' do
      expect(described_class::ALLOSTATIC_LOAD_HEALTHY).to be < described_class::ALLOSTATIC_LOAD_ELEVATED
      expect(described_class::ALLOSTATIC_LOAD_ELEVATED).to be < described_class::ALLOSTATIC_LOAD_CRITICAL
    end
  end

  describe 'SIGNAL_TYPES' do
    it 'defines 3 signal types' do
      expect(described_class::SIGNAL_TYPES).to contain_exactly(:dampen, :amplify, :hold)
    end
  end

  describe 'REGULATION_HEALTH' do
    it 'defines 5 health levels' do
      expect(described_class::REGULATION_HEALTH.size).to eq(5)
    end
  end
end
