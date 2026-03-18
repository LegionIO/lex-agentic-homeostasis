# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FossilFuel::Client do
  subject(:client) { described_class.new }

  it 'includes the runner module' do
    expect(described_class.ancestors).to include(
      Legion::Extensions::Agentic::Homeostasis::FossilFuel::Runners::CognitiveFossilFuel
    )
  end

  it 'responds to create_reserve' do
    expect(client).to respond_to(:create_reserve)
  end

  it 'responds to extract' do
    expect(client).to respond_to(:extract)
  end

  it 'responds to combust' do
    expect(client).to respond_to(:combust)
  end

  it 'responds to list_reserves' do
    expect(client).to respond_to(:list_reserves)
  end

  it 'responds to fuel_status' do
    expect(client).to respond_to(:fuel_status)
  end

  it 'can create and combust through the client' do
    result = client.create_reserve(fuel_type: :coal, domain: :energy, content: 'test')
    expect(result[:success]).to be true
    reserve_id = result[:reserve][:id]
    combust_result = client.combust(reserve_id: reserve_id)
    expect(combust_result[:success]).to be true
  end
end
