# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/temporal_discounting/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Client do
  subject(:client) { described_class.new }

  it 'includes the TemporalDiscounting runner' do
    expect(client).to respond_to(:create_temporal_reward)
    expect(client).to respond_to(:compare_temporal_rewards)
    expect(client).to respond_to(:temporal_patience_report)
  end

  it 'exposes the discounting engine' do
    expect(client.engine).to be_a(Legion::Extensions::Agentic::Homeostasis::TemporalDiscounting::Helpers::DiscountingEngine)
  end

  it 'shares the same engine instance across calls' do
    expect(client.engine).to equal(client.engine)
  end

  it 'creates different engine instances per client' do
    c2 = described_class.new
    expect(client.engine).not_to equal(c2.engine)
  end
end
