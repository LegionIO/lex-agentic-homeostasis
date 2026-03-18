# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weather::Client do
  let(:client) { described_class.new }

  it 'responds to runner methods' do
    expect(client).to respond_to(:create_front)
    expect(client).to respond_to(:brew_storm)
    expect(client).to respond_to(:intensify)
    expect(client).to respond_to(:forecast)
    expect(client).to respond_to(:list_fronts)
    expect(client).to respond_to(:weather_status)
  end

  it 'creates a front successfully' do
    result = client.create_front(front_type: :warm, domain: 'planning')
    expect(result[:success]).to be true
    expect(result[:front][:domain]).to eq('planning')
  end

  it 'brews a storm from an existing front' do
    front_result = client.create_front(front_type: :cold, domain: 'analysis')
    storm_result = client.brew_storm(front_id: front_result[:front][:id], condition: :stormy)
    expect(storm_result[:success]).to be true
  end

  it 'intensifies a storm after brewing' do
    front_result = client.create_front(front_type: :warm, domain: 'x')
    storm_result = client.brew_storm(front_id: front_result[:front][:id], intensity: 0.4)
    intensified  = client.intensify(storm_id: storm_result[:storm][:id])
    expect(intensified[:storm][:intensity]).to be > storm_result[:storm][:intensity]
  end

  it 'returns a forecast reflecting current state' do
    result = client.forecast
    expect(result[:success]).to be true
    expect(result).to have_key(:condition)
  end

  it 'weather_status reflects full atmospheric state' do
    client.create_front(front_type: :stationary, domain: 'bg')
    status = client.weather_status
    expect(status[:front_count]).to eq(1)
    expect(status[:storm_count]).to eq(0)
  end

  it 'maintains isolated engine state per client instance' do
    client2 = described_class.new
    client.create_front(front_type: :warm, domain: 'a')
    expect(client.list_fronts[:count]).to eq(1)
    expect(client2.list_fronts[:count]).to eq(0)
  end

  it 'handles a full weather cycle' do
    # Create a front
    fr = client.create_front(front_type: :cold, domain: 'reasoning', pressure: 0.4)
    expect(fr[:success]).to be true

    # Brew a storm
    sr = client.brew_storm(front_id: fr[:front][:id], condition: :foggy, intensity: 0.3)
    expect(sr[:success]).to be true

    # Intensify the storm
    ir = client.intensify(storm_id: sr[:storm][:id])
    expect(ir[:storm][:intensity]).to be > 0.3

    # Get forecast
    fc = client.forecast
    expect(fc[:active_storms]).to eq(1)

    # Full status
    ws = client.weather_status
    expect(ws[:front_count]).to eq(1)
    expect(ws[:storm_count]).to eq(1)
  end
end
