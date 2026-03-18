# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/weathering/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Weathering::Client do
  let(:client) { described_class.new }

  it 'responds to apply_stressor' do
    expect(client).to respond_to(:apply_stressor)
  end

  it 'responds to recover' do
    expect(client).to respond_to(:recover)
  end

  it 'responds to rest' do
    expect(client).to respond_to(:rest)
  end

  it 'responds to weathering_report' do
    expect(client).to respond_to(:weathering_report)
  end

  it 'responds to integrity_status' do
    expect(client).to respond_to(:integrity_status)
  end

  it 'starts with pristine integrity' do
    status = client.integrity_status
    expect(status[:integrity_label]).to eq('pristine')
  end

  it 'round-trips a full weathering cycle' do
    client.apply_stressor(description: 'Sprint overload', stressor_type: :time_pressure,
                          intensity: 0.85, duration: 7200)
    client.apply_stressor(description: 'Repeated decisions', stressor_type: :decision_fatigue,
                          intensity: 0.7, duration: 3600)
    client.apply_stressor(description: 'Mild task', stressor_type: :monotony,
                          intensity: 0.2, duration: 1800)

    report = client.weathering_report
    expect(report[:stressor_count]).to eq(3)
    expect(report[:integrity]).to be < 1.0
    expect(report[:tempering_level]).to be > 0.0

    client.rest(amount: 1.0)
    after_rest = client.integrity_status
    expect(after_rest[:integrity]).to be > report[:integrity]
  end

  it 'effective_capacity increases with tempering' do
    20.times do
      client.apply_stressor(description: 'Manageable', stressor_type: :complexity,
                            intensity: 0.3, duration: 1800)
    end
    status = client.integrity_status
    expect(status[:tempering_level]).to be > 0.0
    expect(status[:effective_capacity]).to be > 0.0
  end

  it 'each client instance has independent state' do
    client_a = described_class.new
    client_b = described_class.new

    client_a.apply_stressor(description: 'only a', intensity: 0.9, duration: 7200)

    expect(client_a.integrity_status[:integrity]).to be < 1.0
    expect(client_b.integrity_status[:integrity]).to eq(1.0)
  end
end
