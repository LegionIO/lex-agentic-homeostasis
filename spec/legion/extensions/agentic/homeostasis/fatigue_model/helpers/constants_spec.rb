# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FatigueModel::Helpers::Constants do
  let(:mod) { described_class }

  describe 'CHANNELS' do
    it 'defines the five cognitive channels' do
      expect(mod::CHANNELS).to eq(%i[attention working_memory decision_making creative social])
    end

    it 'is frozen' do
      expect(mod::CHANNELS).to be_frozen
    end
  end

  describe 'FATIGUE_LABELS' do
    it 'maps high energy to :fresh' do
      label = mod::FATIGUE_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:fresh)
    end

    it 'maps 0.7 to :alert' do
      label = mod::FATIGUE_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:alert)
    end

    it 'maps 0.5 to :tired' do
      label = mod::FATIGUE_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:tired)
    end

    it 'maps 0.3 to :fatigued' do
      label = mod::FATIGUE_LABELS.find { |range, _| range.cover?(0.3) }&.last
      expect(label).to eq(:fatigued)
    end

    it 'maps 0.1 to :exhausted' do
      label = mod::FATIGUE_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:exhausted)
    end

    it 'is frozen' do
      expect(mod::FATIGUE_LABELS).to be_frozen
    end
  end

  describe 'DEPLETION_RATES' do
    it 'has an entry for each channel' do
      mod::CHANNELS.each do |ch|
        expect(mod::DEPLETION_RATES).to have_key(ch)
      end
    end

    it 'decision_making has the highest rate' do
      expect(mod::DEPLETION_RATES[:decision_making]).to eq(0.06)
    end

    it 'creative has the lowest rate' do
      expect(mod::DEPLETION_RATES[:creative]).to eq(0.03)
    end

    it 'is frozen' do
      expect(mod::DEPLETION_RATES).to be_frozen
    end
  end

  describe 'RECOVERY_RATES' do
    it 'has an entry for each channel' do
      mod::CHANNELS.each do |ch|
        expect(mod::RECOVERY_RATES).to have_key(ch)
      end
    end

    it 'creative has the highest recovery rate' do
      expect(mod::RECOVERY_RATES[:creative]).to eq(0.10)
    end

    it 'decision_making has the lowest recovery rate' do
      expect(mod::RECOVERY_RATES[:decision_making]).to eq(0.04)
    end

    it 'is frozen' do
      expect(mod::RECOVERY_RATES).to be_frozen
    end
  end

  describe 'thresholds' do
    it 'REST_THRESHOLD is 0.3' do
      expect(mod::REST_THRESHOLD).to eq(0.3)
    end

    it 'DELEGATION_THRESHOLD is 0.2' do
      expect(mod::DELEGATION_THRESHOLD).to eq(0.2)
    end

    it 'DEFAULT_ENERGY is 1.0' do
      expect(mod::DEFAULT_ENERGY).to eq(1.0)
    end

    it 'ENERGY_FLOOR is 0.0' do
      expect(mod::ENERGY_FLOOR).to eq(0.0)
    end

    it 'ENERGY_CEILING is 1.0' do
      expect(mod::ENERGY_CEILING).to eq(1.0)
    end
  end
end
