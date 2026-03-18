# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Homeostasis::Client do
  subject(:client) { described_class.new }

  it 'includes the runner module' do
    expect(client).to respond_to(:create_cognitive_variable)
  end

  it 'provides an engine' do
    expect(client.engine).to be_a(Legion::Extensions::Agentic::Homeostasis::Homeostasis::Helpers::HomeostasisEngine)
  end

  it 'creates and manages variables' do
    result = client.create_cognitive_variable(name: 'test')
    expect(result[:success]).to be true
    expect(result[:name]).to eq('test')
  end
end
