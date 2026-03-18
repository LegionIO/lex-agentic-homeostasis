# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Hourglass::Client do
  let(:client) { described_class.new }

  it 'initializes without error' do
    expect { described_class.new }.not_to raise_error
  end

  it 'can create a grain via the client' do
    result = client.create_grain(grain_type: :attention)
    expect(result[:success]).to be(true)
  end

  it 'can create an hourglass via the client' do
    result = client.create_hourglass(grain_type: :focus)
    expect(result[:success]).to be(true)
  end

  it 'can call flow_tick via the client' do
    client.create_hourglass(grain_type: :attention)
    result = client.flow_tick
    expect(result[:success]).to be(true)
  end

  it 'can flip an hourglass via the client' do
    h = client.create_hourglass(grain_type: :attention)
    result = client.flip(hourglass_id: h[:hourglass][:id])
    expect(result[:success]).to be(true)
  end

  it 'can list hourglasses via the client' do
    client.create_hourglass(grain_type: :focus)
    result = client.list_hourglasses
    expect(result[:count]).to eq(1)
  end

  it 'can get time_status via the client' do
    client.create_hourglass(grain_type: :attention)
    result = client.time_status
    expect(result[:success]).to be(true)
    expect(result[:total]).to eq(1)
  end

  it 'maintains its own isolated engine per instance' do
    c1 = described_class.new
    c2 = described_class.new
    c1.create_hourglass(grain_type: :attention)
    expect(c1.list_hourglasses[:count]).to eq(1)
    expect(c2.list_hourglasses[:count]).to eq(0)
  end

  it 'accumulates hourglasses across calls' do
    client.create_hourglass(grain_type: :attention)
    client.create_hourglass(grain_type: :focus)
    result = client.list_hourglasses
    expect(result[:count]).to eq(2)
  end
end
