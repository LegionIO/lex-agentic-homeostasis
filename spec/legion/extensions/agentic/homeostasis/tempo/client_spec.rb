# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/tempo/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tempo::Client do
  let(:client) { described_class.new }

  it 'responds to all tempo runner methods' do
    expect(client).to respond_to(:set_tempo_baseline)
    expect(client).to respond_to(:record_tempo)
    expect(client).to respond_to(:adapt_tempo)
    expect(client).to respond_to(:tempo_status)
    expect(client).to respond_to(:domains_in_sync)
    expect(client).to respond_to(:domains_mismatched)
    expect(client).to respond_to(:tempo_report)
  end

  it 'maintains isolated state per instance' do
    client_a = described_class.new
    client_b = described_class.new

    client_a.record_tempo(domain: :shared, current_tempo: 0.3, task_requirement: 0.6)
    report_b = client_b.tempo_report
    expect(report_b[:total_records]).to eq(0)
  end

  it 'round-trips a full tempo cycle' do
    client.set_tempo_baseline(domain: :analysis, tempo: 0.4)
    client.record_tempo(domain: :analysis, current_tempo: 0.3, task_requirement: 0.7)

    status = client.tempo_status(domain: :analysis)
    expect(status[:found]).to be true
    expect(status[:mismatch_label]).to eq(:mismatched)

    client.adapt_tempo(domain: :analysis, target: 0.7)
    updated = client.tempo_status(domain: :analysis)
    expect(updated[:current_tempo]).to be > 0.3
  end
end
