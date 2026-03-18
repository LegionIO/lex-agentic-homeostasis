# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Homeostasis::Runners::CognitiveHomeostasis do
  subject(:runner) do
    Class.new do
      include Legion::Extensions::Agentic::Homeostasis::Homeostasis::Runners::CognitiveHomeostasis

      def engine
        @engine ||= Legion::Extensions::Agentic::Homeostasis::Homeostasis::Helpers::HomeostasisEngine.new
      end
    end.new
  end

  describe '#create_cognitive_variable' do
    it 'returns success with variable data' do
      result = runner.create_cognitive_variable(name: 'attention')
      expect(result[:success]).to be true
      expect(result[:name]).to eq('attention')
      expect(result[:id]).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#perturb_variable' do
    it 'perturbs a known variable' do
      created = runner.create_cognitive_variable(name: 'x')
      result = runner.perturb_variable(variable_id: created[:id], amount: 0.2)
      expect(result[:success]).to be true
      expect(result[:current_value]).to be_within(0.01).of(0.7)
    end

    it 'returns error for unknown variable' do
      result = runner.perturb_variable(variable_id: 'bad', amount: 0.1)
      expect(result[:success]).to be false
    end
  end

  describe '#correct_variable' do
    it 'corrects a deviated variable' do
      created = runner.create_cognitive_variable(name: 'x')
      runner.perturb_variable(variable_id: created[:id], amount: 0.3)
      result = runner.correct_variable(variable_id: created[:id])
      expect(result[:success]).to be true
      expect(result[:current_value]).to be < 0.8
    end
  end

  describe '#correct_all_variables' do
    it 'returns corrected count' do
      result = runner.correct_all_variables
      expect(result[:success]).to be true
      expect(result[:corrected]).to eq(0)
    end
  end

  describe '#homeostasis_report' do
    it 'returns comprehensive report' do
      runner.create_cognitive_variable(name: 'a')
      result = runner.homeostasis_report
      expect(result).to include(:total_variables, :overall_balance, :stress_index)
    end
  end

  describe '#update_cognitive_homeostasis' do
    it 'returns corrected and stats' do
      result = runner.update_cognitive_homeostasis
      expect(result[:success]).to be true
      expect(result).to include(:corrected, :stats)
    end
  end

  describe '#cognitive_homeostasis_stats' do
    it 'returns engine stats' do
      result = runner.cognitive_homeostasis_stats
      expect(result).to include(:total_variables, :overall_balance)
    end
  end
end
