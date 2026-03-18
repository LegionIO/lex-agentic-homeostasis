# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/metabolism/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Metabolism::Client do
  let(:client) { described_class.new }

  it 'responds to create_reserve' do
    expect(client).to respond_to(:create_reserve)
  end

  it 'responds to spend_energy' do
    expect(client).to respond_to(:spend_energy)
  end

  it 'responds to recover' do
    expect(client).to respond_to(:recover)
  end

  it 'responds to catabolize' do
    expect(client).to respond_to(:catabolize)
  end

  it 'responds to anabolize' do
    expect(client).to respond_to(:anabolize)
  end

  it 'responds to metabolic_status' do
    expect(client).to respond_to(:metabolic_status)
  end

  it 'responds to run_cycle' do
    expect(client).to respond_to(:run_cycle)
  end

  it 'round-trips a full metabolic lifecycle' do
    reserve_result = client.create_reserve(max_energy: 500.0)
    expect(reserve_result[:success]).to be true
    id = reserve_result[:reserve][:id]

    spend_result = client.spend_energy(reserve_id: id, operation_type: :reasoning)
    expect(spend_result[:success]).to be true

    recover_result = client.recover(reserve_id: id, duration: 2.0)
    expect(recover_result[:success]).to be true
    expect(recover_result[:energy_gained]).to be > 0.0

    status = client.metabolic_status(reserve_id: id)
    expect(status[:reserve][:state]).to be_a(Symbol)
  end

  it 'supports catabolism and anabolism cycle' do
    id = client.create_reserve[:reserve][:id]

    catabolism = client.catabolize(reserve_id: id, complexity: 2.0)
    expect(catabolism[:energy_gained]).to be > 0.0

    anabolism = client.anabolize(reserve_id: id, energy_cost: 10.0)
    expect(anabolism[:structure_value]).to be > 0.0
  end

  it 'maintains independent state between two clients' do
    client2 = described_class.new
    id1 = client.create_reserve[:reserve][:id]
    id2 = client2.create_reserve[:reserve][:id]

    client.spend_energy(reserve_id: id1, operation_type: :creativity)
    expect(client2.metabolic_status(reserve_id: id2)[:reserve][:current_energy]).to eq(1000.0)
  end

  it 'run_cycle drains energy proportional to operations' do
    id = client.create_reserve(max_energy: 1000.0)[:reserve][:id]
    result = client.run_cycle(reserve_id: id, operations: %i[creativity reasoning decision])
    expect(result[:energy_spent_this_cycle]).to be > 0.0
    expect(result[:reserve_energy]).to be < 1000.0
  end
end
