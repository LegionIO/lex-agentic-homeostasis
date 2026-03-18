# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Core::Helpers::Setpoint do
  subject(:setpoint) { described_class.new(name: :test, target: 0.5, tolerance: 0.2) }

  describe '#initialize' do
    it 'sets target and tolerance' do
      expect(setpoint.target).to eq(0.5)
      expect(setpoint.tolerance).to eq(0.2)
    end

    it 'starts with current_value at target' do
      expect(setpoint.current_value).to eq(0.5)
    end

    it 'starts with zero error' do
      expect(setpoint.error).to eq(0.0)
    end
  end

  describe '#update' do
    it 'computes positive error when above target' do
      error = setpoint.update(0.8)
      expect(error).to be_within(0.001).of(0.3)
    end

    it 'computes negative error when below target' do
      error = setpoint.update(0.2)
      expect(error).to be_within(0.001).of(-0.3)
    end

    it 'records history' do
      setpoint.update(0.6)
      setpoint.update(0.7)
      expect(setpoint.history.size).to eq(2)
    end
  end

  describe '#within_tolerance?' do
    it 'returns true when error is small' do
      setpoint.update(0.6) # error = 0.1, tolerance = 0.2
      expect(setpoint.within_tolerance?).to be true
    end

    it 'returns false when error exceeds tolerance' do
      setpoint.update(0.9) # error = 0.4, tolerance = 0.2
      expect(setpoint.within_tolerance?).to be false
    end
  end

  describe '#deviation_ratio' do
    it 'returns 0 when at target' do
      setpoint.update(0.5)
      expect(setpoint.deviation_ratio).to eq(0.0)
    end

    it 'returns 1.0 when at tolerance boundary' do
      setpoint.update(0.7)
      expect(setpoint.deviation_ratio).to be_within(0.001).of(1.0)
    end

    it 'clamps at 3.0 for extreme deviations' do
      setpoint.update(1.0)
      expect(setpoint.deviation_ratio).to be <= 3.0
    end
  end

  describe '#adapt_target' do
    it 'shifts target toward current value' do
      setpoint.update(0.7)
      original_target = setpoint.target
      setpoint.adapt_target
      expect(setpoint.target).to be > original_target
    end

    it 'clamps target between 0 and 1' do
      setpoint.update(1.5)
      setpoint.adapt_target(alpha: 0.9)
      expect(setpoint.target).to be <= 1.0
    end
  end

  describe '#trend' do
    it 'returns :insufficient_data with few observations' do
      setpoint.update(0.5)
      expect(setpoint.trend).to eq(:insufficient_data)
    end

    it 'detects rising trend' do
      5.times { |i| setpoint.update(0.5 + (i * 0.05)) }
      expect(setpoint.trend).to eq(:rising)
    end

    it 'detects falling trend' do
      5.times { |i| setpoint.update(0.8 - (i * 0.05)) }
      expect(setpoint.trend).to eq(:falling)
    end

    it 'detects stable trend' do
      5.times { setpoint.update(0.5) }
      expect(setpoint.trend).to eq(:stable)
    end
  end

  describe '#to_h' do
    it 'returns a complete status hash' do
      setpoint.update(0.6)
      h = setpoint.to_h
      expect(h).to include(:name, :target, :tolerance, :current_value, :error,
                           :within_tolerance, :deviation_ratio, :trend, :history_size)
    end
  end
end
