# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Homeostasis::Helpers::HomeostasisEngine do
  subject(:engine) { described_class.new }

  describe '#create_variable' do
    it 'returns a CognitiveVariable' do
      var = engine.create_variable(name: 'attention')
      expect(var).to be_a(Legion::Extensions::Agentic::Homeostasis::Homeostasis::Helpers::CognitiveVariable)
    end

    it 'accepts category and setpoint' do
      var = engine.create_variable(name: 'load', category: :cognitive_load, setpoint: 0.3)
      expect(var.category).to eq(:cognitive_load)
      expect(var.setpoint).to eq(0.3)
    end
  end

  describe '#perturb' do
    it 'perturbs a known variable' do
      var = engine.create_variable(name: 'x')
      result = engine.perturb(variable_id: var.id, amount: 0.2)
      expect(result.current_value).to be_within(0.01).of(0.7)
    end

    it 'returns nil for unknown id' do
      expect(engine.perturb(variable_id: 'bad', amount: 0.1)).to be_nil
    end
  end

  describe '#correct' do
    it 'corrects a deviated variable' do
      var = engine.create_variable(name: 'x')
      engine.perturb(variable_id: var.id, amount: 0.3)
      engine.correct(variable_id: var.id)
      expect(var.current_value).to be < 0.8
    end
  end

  describe '#correct_all' do
    it 'corrects all out-of-range variables' do
      v1 = engine.create_variable(name: 'a')
      engine.create_variable(name: 'b')
      engine.perturb(variable_id: v1.id, amount: 0.3)
      count = engine.correct_all
      expect(count).to eq(1)
    end
  end

  describe '#drift_all' do
    it 'returns the count of variables drifted' do
      engine.create_variable(name: 'a')
      engine.create_variable(name: 'b')
      expect(engine.drift_all).to eq(2)
    end
  end

  describe '#reset_variable' do
    it 'resets variable to setpoint' do
      var = engine.create_variable(name: 'x')
      engine.perturb(variable_id: var.id, amount: 0.3)
      engine.reset_variable(variable_id: var.id)
      expect(var.current_value).to eq(var.setpoint)
    end
  end

  describe '#out_of_range_variables' do
    it 'returns empty when all in range' do
      engine.create_variable(name: 'a')
      expect(engine.out_of_range_variables).to be_empty
    end

    it 'returns deviated variables' do
      var = engine.create_variable(name: 'a')
      engine.perturb(variable_id: var.id, amount: 0.4)
      expect(engine.out_of_range_variables.size).to eq(1)
    end
  end

  describe '#variables_by_category' do
    it 'filters by category' do
      engine.create_variable(name: 'a', category: :arousal)
      engine.create_variable(name: 'b', category: :attention)
      result = engine.variables_by_category(category: :arousal)
      expect(result.size).to eq(1)
      expect(result.first.name).to eq('a')
    end
  end

  describe '#most_deviated' do
    it 'returns variables sorted by deviation desc' do
      v1 = engine.create_variable(name: 'a')
      v2 = engine.create_variable(name: 'b')
      engine.perturb(variable_id: v1.id, amount: 0.1)
      engine.perturb(variable_id: v2.id, amount: 0.4)
      result = engine.most_deviated(limit: 2)
      expect(result.first.name).to eq('b')
    end
  end

  describe '#overall_balance' do
    it 'returns 1.0 when all at setpoint' do
      engine.create_variable(name: 'a')
      expect(engine.overall_balance).to eq(1.0)
    end

    it 'decreases when variables deviate' do
      var = engine.create_variable(name: 'a')
      engine.perturb(variable_id: var.id, amount: 0.4)
      expect(engine.overall_balance).to be < 1.0
    end

    it 'returns 1.0 with no variables' do
      expect(engine.overall_balance).to eq(1.0)
    end
  end

  describe '#stress_index' do
    it 'returns 0.0 when all at setpoint' do
      engine.create_variable(name: 'a')
      expect(engine.stress_index).to eq(0.0)
    end

    it 'returns 0.0 with no variables' do
      expect(engine.stress_index).to eq(0.0)
    end
  end

  describe '#homeostasis_report' do
    it 'returns comprehensive report' do
      engine.create_variable(name: 'a')
      report = engine.homeostasis_report
      expect(report).to include(:total_variables, :in_range_count, :out_of_range_count,
                                :overall_balance, :stress_index, :most_deviated,
                                :category_breakdown)
    end
  end

  describe '#to_h' do
    it 'returns engine stats' do
      engine.create_variable(name: 'a')
      h = engine.to_h
      expect(h).to include(:total_variables, :overall_balance, :stress_index)
    end
  end
end
