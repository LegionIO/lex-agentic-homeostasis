# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/fatigue_model/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FatigueModel::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:process_cognitive_task)
    expect(client).to respond_to(:rest_cognitive_channel)
    expect(client).to respond_to(:rest_all_channels)
    expect(client).to respond_to(:channel_fatigue_status)
    expect(client).to respond_to(:overall_fatigue_report)
    expect(client).to respond_to(:fatigue_recommendations)
    expect(client).to respond_to(:cognitive_quality_report)
    expect(client).to respond_to(:update_cognitive_fatigue_model)
    expect(client).to respond_to(:cognitive_fatigue_model_stats)
  end

  it 'maintains independent engine state per instance' do
    client2 = described_class.new
    client.process_cognitive_task(channel_name: :attention)
    expect(client.channel_fatigue_status(channel_name: :attention)[:energy]).to be < 1.0
    expect(client2.channel_fatigue_status(channel_name: :attention)[:energy]).to eq(1.0)
  end

  it 'processes a full depletion-rest cycle' do
    5.times { client.process_cognitive_task(channel_name: :social) }
    depleted = client.channel_fatigue_status(channel_name: :social)[:energy]
    client.rest_cognitive_channel(channel_name: :social)
    recovered = client.channel_fatigue_status(channel_name: :social)[:energy]
    expect(recovered).to be > depleted
  end

  it 'accumulates tasks across multiple channels' do
    client.process_cognitive_task(channel_name: :attention)
    client.process_cognitive_task(channel_name: :creative)
    report = client.cognitive_fatigue_model_stats
    expect(report[:overall_fatigue]).to be < 1.0
  end
end
