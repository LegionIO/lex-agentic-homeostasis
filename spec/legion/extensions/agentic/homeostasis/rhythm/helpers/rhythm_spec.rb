# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::Rhythm do
  let(:fixed_time) { Time.utc(2026, 1, 1, 12, 0, 0) }

  subject(:rhythm) do
    r = described_class.new(
      id:           :r_focus,
      name:         'focus ultradian',
      rhythm_type:  :ultradian,
      dimension:    :focus,
      period:       5400,
      amplitude:    0.8,
      phase_offset: 0.0
    )
    # Fix created_at to a known reference point
    r.instance_variable_set(:@created_at, fixed_time)
    r
  end

  describe '#initialize' do
    it 'sets id, name, rhythm_type, dimension' do
      expect(rhythm.id).to eq(:r_focus)
      expect(rhythm.name).to eq('focus ultradian')
      expect(rhythm.rhythm_type).to eq(:ultradian)
      expect(rhythm.dimension).to eq(:focus)
    end

    it 'sets period, amplitude, phase_offset' do
      expect(rhythm.period).to eq(5400)
      expect(rhythm.amplitude).to eq(0.8)
      expect(rhythm.phase_offset).to eq(0.0)
    end

    it 'clamps amplitude to 0..1' do
      r = described_class.new(id: :x, name: 'x', rhythm_type: :custom,
                              dimension: :focus, period: 100, amplitude: 2.5)
      expect(r.amplitude).to eq(1.0)
    end

    it 'clamps amplitude floor to 0.0' do
      r = described_class.new(id: :x, name: 'x', rhythm_type: :custom,
                              dimension: :focus, period: 100, amplitude: -0.5)
      expect(r.amplitude).to eq(0.0)
    end

    it 'sets created_at' do
      expect(rhythm.created_at).to be_a(Time)
    end
  end

  describe '#value_at' do
    it 'returns 0.5 * amplitude at start (sin(0) = 0)' do
      val = rhythm.value_at(fixed_time)
      expect(val).to be_within(0.001).of(0.4)
    end

    it 'returns near amplitude at quarter period (sin(PI/2) = 1)' do
      quarter = Time.at(fixed_time.to_f + (5400 / 4.0))
      val = rhythm.value_at(quarter)
      expect(val).to be_within(0.001).of(0.8)
    end

    it 'returns near 0 at three-quarter period (sin(3*PI/2) = -1)' do
      three_quarter = Time.at(fixed_time.to_f + (5400 * 0.75))
      val = rhythm.value_at(three_quarter)
      expect(val).to be_within(0.001).of(0.0)
    end

    it 'returns values in range 0..amplitude' do
      100.times do |i|
        t = Time.at(fixed_time.to_f + (i * 54))
        expect(rhythm.value_at(t)).to be_between(0.0, 0.8)
      end
    end
  end

  describe '#phase_at' do
    it 'returns 0.0 at start' do
      expect(rhythm.phase_at(fixed_time)).to be_within(0.0001).of(0.0)
    end

    it 'returns 0.25 at quarter period' do
      quarter = Time.at(fixed_time.to_f + (5400 / 4.0))
      expect(rhythm.phase_at(quarter)).to be_within(0.0001).of(0.25)
    end

    it 'returns 0.5 at half period' do
      half = Time.at(fixed_time.to_f + (5400 / 2.0))
      expect(rhythm.phase_at(half)).to be_within(0.0001).of(0.5)
    end

    it 'returns 0.75 at three-quarter period' do
      three_quarter = Time.at(fixed_time.to_f + (5400 * 0.75))
      expect(rhythm.phase_at(three_quarter)).to be_within(0.0001).of(0.75)
    end
  end

  describe '#current_value' do
    it 'returns a Float' do
      allow(Time).to receive(:now).and_return(fixed_time)
      expect(rhythm.current_value).to be_a(Float)
    end
  end

  describe '#current_phase' do
    it 'returns a Float between 0 and 1' do
      allow(Time).to receive(:now).and_return(fixed_time)
      expect(rhythm.current_phase).to be_between(0.0, 1.0)
    end
  end

  describe '#phase_label' do
    it 'returns :rising at phase 0.0' do
      allow(Time).to receive(:now).and_return(fixed_time)
      expect(rhythm.phase_label).to eq(:rising)
    end

    it 'returns :peak at phase 0.3' do
      peak_time = Time.at(fixed_time.to_f + (5400 * 0.3))
      allow(Time).to receive(:now).and_return(peak_time)
      expect(rhythm.phase_label).to eq(:peak)
    end

    it 'returns :falling at phase 0.6' do
      falling_time = Time.at(fixed_time.to_f + (5400 * 0.6))
      allow(Time).to receive(:now).and_return(falling_time)
      expect(rhythm.phase_label).to eq(:falling)
    end

    it 'returns :trough at phase 0.8' do
      trough_time = Time.at(fixed_time.to_f + (5400 * 0.8))
      allow(Time).to receive(:now).and_return(trough_time)
      expect(rhythm.phase_label).to eq(:trough)
    end
  end

  describe '#amplitude_label' do
    it 'returns :high for amplitude 0.8' do
      expect(rhythm.amplitude_label).to eq(:high)
    end

    it 'returns :moderate for amplitude 0.5' do
      r = described_class.new(id: :x, name: 'x', rhythm_type: :custom,
                              dimension: :focus, period: 100, amplitude: 0.5)
      expect(r.amplitude_label).to eq(:moderate)
    end

    it 'returns :low for amplitude 0.1' do
      r = described_class.new(id: :x, name: 'x', rhythm_type: :custom,
                              dimension: :focus, period: 100, amplitude: 0.1)
      expect(r.amplitude_label).to eq(:low)
    end

    it 'returns :moderate_high for amplitude 0.7' do
      r = described_class.new(id: :x, name: 'x', rhythm_type: :custom,
                              dimension: :focus, period: 100, amplitude: 0.7)
      expect(r.amplitude_label).to eq(:moderate_high)
    end

    it 'returns :moderate_low for amplitude 0.3' do
      r = described_class.new(id: :x, name: 'x', rhythm_type: :custom,
                              dimension: :focus, period: 100, amplitude: 0.3)
      expect(r.amplitude_label).to eq(:moderate_low)
    end
  end

  describe '#peak? / #trough? / #rising? / #falling?' do
    it 'returns true for rising at start' do
      allow(Time).to receive(:now).and_return(fixed_time)
      expect(rhythm.rising?).to be true
      expect(rhythm.peak?).to be false
      expect(rhythm.trough?).to be false
      expect(rhythm.falling?).to be false
    end

    it 'peak? is true at phase 0.3' do
      peak_time = Time.at(fixed_time.to_f + (5400 * 0.3))
      allow(Time).to receive(:now).and_return(peak_time)
      expect(rhythm.peak?).to be true
    end

    it 'trough? is true at phase 0.8' do
      trough_time = Time.at(fixed_time.to_f + (5400 * 0.8))
      allow(Time).to receive(:now).and_return(trough_time)
      expect(rhythm.trough?).to be true
    end

    it 'falling? is true at phase 0.6' do
      falling_time = Time.at(fixed_time.to_f + (5400 * 0.6))
      allow(Time).to receive(:now).and_return(falling_time)
      expect(rhythm.falling?).to be true
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      allow(Time).to receive(:now).and_return(fixed_time)
      h = rhythm.to_h
      expect(h).to include(
        :id, :name, :rhythm_type, :dimension, :period,
        :amplitude, :phase_offset, :current_value, :current_phase,
        :phase_label, :amplitude_label
      )
    end

    it 'rounds current_value and current_phase to 4 decimal places' do
      allow(Time).to receive(:now).and_return(fixed_time)
      h = rhythm.to_h
      expect(h[:current_value].to_s).to match(/\A\d+\.\d{1,4}\z/)
    end
  end
end
