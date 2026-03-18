# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Homeostasis::Helpers::Constants do
  let(:klass) { Class.new { include Legion::Extensions::Agentic::Homeostasis::Homeostasis::Helpers::Constants } }

  it 'defines MAX_VARIABLES' do
    expect(klass::MAX_VARIABLES).to eq(100)
  end

  it 'defines DEFAULT_SETPOINT' do
    expect(klass::DEFAULT_SETPOINT).to eq(0.5)
  end

  it 'defines BALANCE_LABELS as a frozen hash' do
    expect(klass::BALANCE_LABELS).to be_frozen
    expect(klass::BALANCE_LABELS.size).to eq(5)
  end

  it 'defines DEVIATION_LABELS as a frozen hash' do
    expect(klass::DEVIATION_LABELS).to be_frozen
  end

  it 'defines VARIABLE_CATEGORIES as a frozen array' do
    expect(klass::VARIABLE_CATEGORIES).to be_frozen
    expect(klass::VARIABLE_CATEGORIES).to include(:arousal, :attention, :cognitive_load)
  end
end
