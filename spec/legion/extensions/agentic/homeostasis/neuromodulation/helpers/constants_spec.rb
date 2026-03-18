# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Helpers::Constants do
  let(:mod) { Legion::Extensions::Agentic::Homeostasis::Neuromodulation::Helpers::Constants }

  describe 'MODULATORS' do
    it 'contains the four neuromodulator names' do
      expect(mod::MODULATORS).to contain_exactly(:dopamine, :serotonin, :norepinephrine, :acetylcholine)
    end

    it 'is frozen' do
      expect(mod::MODULATORS).to be_frozen
    end
  end

  describe 'OPTIMAL_RANGES' do
    it 'defines a range for each modulator' do
      mod::MODULATORS.each do |name|
        expect(mod::OPTIMAL_RANGES[name]).to be_a(Range)
      end
    end

    it 'has non-overlapping floor/ceiling bounds' do
      mod::OPTIMAL_RANGES.each_value do |range|
        expect(range.begin).to be >= mod::LEVEL_FLOOR
        expect(range.end).to be <= mod::LEVEL_CEILING
      end
    end
  end

  describe 'numeric constants' do
    it 'DEFAULT_LEVEL is 0.5' do
      expect(mod::DEFAULT_LEVEL).to eq(0.5)
    end

    it 'LEVEL_FLOOR is 0.0' do
      expect(mod::LEVEL_FLOOR).to eq(0.0)
    end

    it 'LEVEL_CEILING is 1.0' do
      expect(mod::LEVEL_CEILING).to eq(1.0)
    end

    it 'MODULATION_ALPHA is 0.15' do
      expect(mod::MODULATION_ALPHA).to eq(0.15)
    end

    it 'BASELINE_DRIFT is 0.01' do
      expect(mod::BASELINE_DRIFT).to eq(0.01)
    end

    it 'MAX_EVENTS is 200' do
      expect(mod::MAX_EVENTS).to eq(200)
    end
  end

  describe 'STATE_LABELS' do
    it 'defines high/optimal/low labels for each modulator' do
      mod::MODULATORS.each do |name|
        expect(mod::STATE_LABELS[name]).to have_key(:high)
        expect(mod::STATE_LABELS[name]).to have_key(:optimal)
        expect(mod::STATE_LABELS[name]).to have_key(:low)
      end
    end
  end
end
