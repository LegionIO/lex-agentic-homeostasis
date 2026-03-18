# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Homeostasis::Helpers::CognitiveVariable do
  subject(:variable) { described_class.new(name: 'arousal', category: :arousal) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(variable.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets name and category' do
      expect(variable.name).to eq('arousal')
      expect(variable.category).to eq(:arousal)
    end

    it 'defaults to setpoint value' do
      expect(variable.current_value).to eq(0.5)
      expect(variable.setpoint).to eq(0.5)
    end

    it 'accepts custom initial_value' do
      v = described_class.new(name: 'x', initial_value: 0.8)
      expect(v.current_value).to eq(0.8)
    end

    it 'clamps setpoint to 0..1' do
      v = described_class.new(name: 'x', setpoint: 1.5)
      expect(v.setpoint).to eq(1.0)
    end
  end

  describe '#deviation' do
    it 'returns 0 when at setpoint' do
      expect(variable.deviation).to eq(0.0)
    end

    it 'returns absolute difference from setpoint' do
      variable.perturb!(amount: 0.2)
      expect(variable.deviation).to be_within(0.01).of(0.2)
    end
  end

  describe '#in_range?' do
    it 'returns true when within tolerance' do
      expect(variable.in_range?).to be true
    end

    it 'returns false when outside tolerance' do
      variable.perturb!(amount: 0.3)
      expect(variable.in_range?).to be false
    end
  end

  describe '#balance_score' do
    it 'returns 1.0 when at setpoint' do
      expect(variable.balance_score).to eq(1.0)
    end

    it 'decreases with deviation' do
      variable.perturb!(amount: 0.3)
      expect(variable.balance_score).to be < 1.0
    end
  end

  describe '#balance_label' do
    it 'returns :optimal when at setpoint' do
      expect(variable.balance_label).to eq(:optimal)
    end
  end

  describe '#deviation_label' do
    it 'returns :negligible when at setpoint' do
      expect(variable.deviation_label).to eq(:negligible)
    end

    it 'returns :moderate for significant deviation' do
      variable.perturb!(amount: 0.3)
      expect(variable.deviation_label).to eq(:moderate)
    end
  end

  describe '#perturb!' do
    it 'changes current_value' do
      variable.perturb!(amount: 0.1)
      expect(variable.current_value).to be_within(0.01).of(0.6)
    end

    it 'clamps to 0..1' do
      variable.perturb!(amount: 2.0)
      expect(variable.current_value).to eq(1.0)
    end

    it 'allows negative perturbation' do
      variable.perturb!(amount: -0.3)
      expect(variable.current_value).to be_within(0.01).of(0.2)
    end
  end

  describe '#correct!' do
    it 'moves value toward setpoint' do
      variable.perturb!(amount: 0.3)
      before = variable.current_value
      variable.correct!
      expect(variable.current_value).to be < before
    end

    it 'does nothing when in range' do
      before = variable.current_value
      variable.correct!
      expect(variable.current_value).to eq(before)
    end

    it 'increments correction_count' do
      variable.perturb!(amount: 0.3)
      variable.correct!
      expect(variable.correction_count).to eq(1)
    end
  end

  describe '#drift!' do
    it 'changes value slightly' do
      srand(42)
      before = variable.current_value
      variable.drift!
      expect(variable.current_value).not_to eq(before)
    end
  end

  describe '#reset!' do
    it 'returns to setpoint' do
      variable.perturb!(amount: 0.3)
      variable.reset!
      expect(variable.current_value).to eq(variable.setpoint)
    end
  end

  describe '#to_h' do
    it 'returns complete hash representation' do
      h = variable.to_h
      expect(h).to include(:id, :name, :category, :setpoint, :tolerance,
                           :current_value, :deviation, :deviation_label,
                           :in_range, :balance_score, :balance_label,
                           :correction_count, :correction_rate, :created_at)
    end
  end
end
