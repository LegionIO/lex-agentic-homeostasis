# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/surplus/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Surplus::Client do
  it 'responds to surplus runner methods' do
    client = described_class.new
    expect(client).to respond_to(:surplus_status)
    expect(client).to respond_to(:allocate_surplus)
    expect(client).to respond_to(:release_surplus)
    expect(client).to respond_to(:commit_capacity)
    expect(client).to respond_to(:uncommit_capacity)
    expect(client).to respond_to(:replenish_surplus)
    expect(client).to respond_to(:deplete_surplus)
    expect(client).to respond_to(:surplus_allocations)
  end
end
