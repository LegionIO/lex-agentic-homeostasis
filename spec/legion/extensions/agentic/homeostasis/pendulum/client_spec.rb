# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/pendulum/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Pendulum::Client do
  it 'responds to runner methods' do
    client = described_class.new
    expect(client).to respond_to(:create_pendulum)
    expect(client).to respond_to(:swing)
    expect(client).to respond_to(:damp_all)
    expect(client).to respond_to(:check_resonance)
    expect(client).to respond_to(:get_dominant_pole)
    expect(client).to respond_to(:most_active)
    expect(client).to respond_to(:most_damped)
    expect(client).to respond_to(:pendulum_report)
    expect(client).to respond_to(:get_pendulum)
  end

  it 'creates a fresh engine per instance' do
    c1 = described_class.new
    c2 = described_class.new
    c1.create_pendulum(pole_pair: :certainty_doubt)
    expect(c2.pendulum_report[:report][:total]).to eq(0)
  end
end
