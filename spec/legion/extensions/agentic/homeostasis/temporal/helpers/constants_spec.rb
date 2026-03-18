# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Temporal::Helpers::Constants do
  it 'defines urgency horizons' do
    expect(described_class::URGENCY_HORIZONS.size).to eq(5)
  end

  it 'has increasing horizon values' do
    values = described_class::URGENCY_HORIZONS.values
    expect(values).to eq(values.sort)
  end

  it 'defines 5 urgency levels' do
    expect(described_class::URGENCY_LEVELS.size).to eq(5)
  end

  it 'defines deadline urgency thresholds' do
    expect(described_class::DEADLINE_URGENCY.size).to eq(5)
  end

  it 'defines 4 pattern types' do
    expect(described_class::PATTERN_TYPES.size).to eq(4)
  end

  it 'defines dilation range with min and max' do
    range = described_class::DILATION_RANGE
    expect(range[:min]).to be < range[:max]
  end

  it 'has a positive subjective alpha' do
    expect(described_class::SUBJECTIVE_ALPHA).to be_between(0.0, 1.0)
  end
end
