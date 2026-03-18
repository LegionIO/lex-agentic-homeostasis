# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Core::Client do
  it 'creates default regulator and allostatic load' do
    client = described_class.new
    expect(client.regulator).to be_a(Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Regulator)
    expect(client.allostatic_load).to be_a(Legion::Extensions::Agentic::Homeostasis::Core::Helpers::AllostaticLoad)
  end

  it 'accepts injected dependencies' do
    reg = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Regulator.new
    al = Legion::Extensions::Agentic::Homeostasis::Core::Helpers::AllostaticLoad.new
    client = described_class.new(regulator: reg, allostatic_load: al)
    expect(client.regulator).to equal(reg)
    expect(client.allostatic_load).to equal(al)
  end

  it 'includes Homeostasis runner methods' do
    client = described_class.new
    expect(client).to respond_to(:regulate, :modulation_for, :allostatic_status,
                                 :regulation_overview, :homeostasis_stats)
  end
end
