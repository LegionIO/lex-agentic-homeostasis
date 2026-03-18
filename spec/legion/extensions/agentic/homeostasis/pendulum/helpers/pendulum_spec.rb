# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Pendulum::Helpers::Pendulum do
  subject(:pendulum) { described_class.new(pole_pair: :certainty_doubt) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(pendulum.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores the pole_pair' do
      expect(pendulum.pole_pair).to eq(:certainty_doubt)
    end

    it 'defaults amplitude to 0.5' do
      expect(pendulum.amplitude).to eq(0.5)
    end

    it 'defaults period to 10.0' do
      expect(pendulum.period).to eq(10.0)
    end

    it 'defaults damping to DAMPING_RATE' do
      expect(pendulum.damping).to eq(Legion::Extensions::Agentic::Homeostasis::Pendulum::Helpers::Constants::DAMPING_RATE)
    end

    it 'initializes current_position to 0.0' do
      expect(pendulum.current_position).to eq(0.0)
    end

    it 'initializes swings to 0' do
      expect(pendulum.swings).to eq(0)
    end

    it 'sets created_at' do
      expect(pendulum.created_at).to be_a(Time)
    end

    it 'raises for invalid pole_pair' do
      expect { described_class.new(pole_pair: :nonsense) }.to raise_error(ArgumentError)
    end

    it 'raises when amplitude out of range' do
      expect { described_class.new(pole_pair: :certainty_doubt, amplitude: 1.5) }.to raise_error(ArgumentError)
    end

    it 'raises when period is zero or negative' do
      expect { described_class.new(pole_pair: :certainty_doubt, period: 0.0) }.to raise_error(ArgumentError)
    end

    it 'raises when damping is negative' do
      expect { described_class.new(pole_pair: :certainty_doubt, damping: -0.1) }.to raise_error(ArgumentError)
    end

    it 'accepts custom amplitude' do
      p = described_class.new(pole_pair: :focus_diffusion, amplitude: 0.8)
      expect(p.amplitude).to eq(0.8)
    end

    it 'accepts custom period' do
      p = described_class.new(pole_pair: :focus_diffusion, period: 30.0)
      expect(p.period).to eq(30.0)
    end

    it 'accepts zero damping' do
      p = described_class.new(pole_pair: :analysis_intuition, damping: 0.0)
      expect(p.damping).to eq(0.0)
    end
  end

  describe '#swing!' do
    it 'moves position toward positive with positive force' do
      pendulum.swing!(force: 0.5)
      expect(pendulum.current_position).to be > 0.0
    end

    it 'moves position toward negative with negative force' do
      pendulum.swing!(force: -0.5)
      expect(pendulum.current_position).to be < 0.0
    end

    it 'clamps position to 1.0 maximum' do
      5.times { pendulum.swing!(force: 1.0) }
      expect(pendulum.current_position).to eq(1.0)
    end

    it 'clamps position to -1.0 minimum' do
      5.times { pendulum.swing!(force: -1.0) }
      expect(pendulum.current_position).to eq(-1.0)
    end

    it 'clamps force to valid range' do
      pendulum.swing!(force: 99.0)
      expect(pendulum.current_position).to be <= 1.0
    end

    it 'increments swing count' do
      pendulum.swing!(force: 0.3)
      expect(pendulum.swings).to eq(1)
    end

    it 'returns the new position' do
      result = pendulum.swing!(force: 0.4)
      expect(result).to eq(pendulum.current_position)
    end
  end

  describe '#damp!' do
    it 'reduces amplitude' do
      original = pendulum.amplitude
      pendulum.damp!
      expect(pendulum.amplitude).to be < original
    end

    it 'reduces current_position magnitude' do
      pendulum.swing!(force: 0.8)
      original = pendulum.current_position.abs
      pendulum.damp!
      expect(pendulum.current_position.abs).to be < original
    end

    it 'returns the new amplitude' do
      result = pendulum.damp!
      expect(result).to eq(pendulum.amplitude)
    end

    it 'never goes below 0' do
      100.times { pendulum.damp! }
      expect(pendulum.amplitude).to be >= 0.0
    end
  end

  describe '#position_at' do
    let(:p) { described_class.new(pole_pair: :focus_diffusion, amplitude: 1.0, period: 10.0, damping: 0.0) }

    it 'returns a float' do
      expect(p.position_at(0.0)).to be_a(Float)
    end

    it 'returns amplitude at time 0 (cos(0) = 1)' do
      expect(p.position_at(0.0)).to eq(1.0)
    end

    it 'returns a value within [-1.0, 1.0]' do
      expect(p.position_at(5.0)).to be_between(-1.0, 1.0)
    end

    it 'decays with positive damping' do
      damped = described_class.new(pole_pair: :focus_diffusion, amplitude: 1.0, period: 10.0, damping: 0.1)
      expect(damped.position_at(10.0).abs).to be < p.position_at(10.0).abs
    end
  end

  describe '#at_pole_a?' do
    it 'is false at neutral position' do
      expect(pendulum.at_pole_a?).to be false
    end

    it 'is true when position <= -0.5' do
      3.times { pendulum.swing!(force: -1.0) }
      expect(pendulum.at_pole_a?).to be true
    end
  end

  describe '#at_pole_b?' do
    it 'is false at neutral position' do
      expect(pendulum.at_pole_b?).to be false
    end

    it 'is true when position >= 0.5' do
      3.times { pendulum.swing!(force: 1.0) }
      expect(pendulum.at_pole_b?).to be true
    end
  end

  describe '#amplitude_label' do
    it 'returns :moderate for default amplitude' do
      expect(pendulum.amplitude_label).to eq(:moderate)
    end

    it 'returns :minimal for low amplitude' do
      p = described_class.new(pole_pair: :certainty_doubt, amplitude: 0.1)
      expect(p.amplitude_label).to eq(:minimal)
    end

    it 'returns :maximal for high amplitude' do
      p = described_class.new(pole_pair: :certainty_doubt, amplitude: 0.9)
      expect(p.amplitude_label).to eq(:maximal)
    end
  end

  describe '#resonant_with?' do
    let(:p) { described_class.new(pole_pair: :analysis_intuition, period: 10.0) }

    it 'returns true when frequency matches natural frequency' do
      natural = 1.0 / 10.0
      expect(p.resonant_with?(natural)).to be true
    end

    it 'returns false when frequency is far off' do
      expect(p.resonant_with?(0.5)).to be false
    end

    it 'returns false for zero or negative frequency' do
      expect(p.resonant_with?(0.0)).to be false
    end

    it 'returns true within 5% tolerance' do
      natural = 1.0 / 10.0
      expect(p.resonant_with?(natural * 1.04)).to be true
    end
  end

  describe '#dominant_pole' do
    it 'returns :neutral near center' do
      expect(pendulum.dominant_pole).to eq(:neutral)
    end

    it 'returns pole_a when position is negative' do
      3.times { pendulum.swing!(force: -1.0) }
      expect(pendulum.dominant_pole).to eq(:certainty)
    end

    it 'returns pole_b when position is positive' do
      3.times { pendulum.swing!(force: 1.0) }
      expect(pendulum.dominant_pole).to eq(:doubt)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = pendulum.to_h
      %i[id pole_pair pole_a pole_b amplitude amplitude_label period damping
         current_position dominant_pole at_pole_a at_pole_b swings created_at].each do |key|
        expect(h).to have_key(key)
      end
    end

    it 'pole_a is :certainty for certainty_doubt pair' do
      expect(pendulum.to_h[:pole_a]).to eq(:certainty)
    end

    it 'pole_b is :doubt for certainty_doubt pair' do
      expect(pendulum.to_h[:pole_b]).to eq(:doubt)
    end
  end
end
