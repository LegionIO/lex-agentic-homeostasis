# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Temporal::Client do
  it 'creates default temporal store' do
    client = described_class.new
    expect(client.temporal_store).to be_a(Legion::Extensions::Agentic::Homeostasis::Temporal::Helpers::TemporalStore)
  end

  it 'accepts injected temporal store' do
    store = Legion::Extensions::Agentic::Homeostasis::Temporal::Helpers::TemporalStore.new
    client = described_class.new(temporal_store: store)
    expect(client.temporal_store).to equal(store)
  end

  it 'includes Temporal runner methods' do
    client = described_class.new
    expect(client).to respond_to(:mark_event, :elapsed_since, :set_deadline,
                                 :check_deadlines, :temporal_stats)
  end
end
