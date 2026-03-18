# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Pendulum::Helpers::PendulumEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts with empty pendulums hash' do
      expect(engine.pendulums).to be_empty
    end

    it 'reports count of 0' do
      expect(engine.count).to eq(0)
    end
  end

  describe '#create_pendulum' do
    it 'creates a pendulum and returns it' do
      p = engine.create_pendulum(pole_pair: :certainty_doubt)
      expect(p).to be_a(Legion::Extensions::Agentic::Homeostasis::Pendulum::Helpers::Pendulum)
    end

    it 'stores the pendulum by id' do
      p = engine.create_pendulum(pole_pair: :focus_diffusion)
      expect(engine.pendulums[p.id]).to eq(p)
    end

    it 'increments count' do
      engine.create_pendulum(pole_pair: :certainty_doubt)
      expect(engine.count).to eq(1)
    end

    it 'accepts amplitude, period, and damping' do
      p = engine.create_pendulum(pole_pair: :analysis_intuition, amplitude: 0.8, period: 20.0, damping: 0.05)
      expect(p.amplitude).to eq(0.8)
      expect(p.period).to eq(20.0)
      expect(p.damping).to eq(0.05)
    end

    it 'raises when max pendulums reached' do
      Legion::Extensions::Agentic::Homeostasis::Pendulum::Helpers::Constants::MAX_PENDULUMS.times do
        engine.create_pendulum(pole_pair: :certainty_doubt)
      end
      expect { engine.create_pendulum(pole_pair: :certainty_doubt) }.to raise_error(ArgumentError, /max pendulums/)
    end
  end

  describe '#swing' do
    let!(:pendulum) { engine.create_pendulum(pole_pair: :focus_diffusion) }

    it 'swings the pendulum and returns it' do
      result = engine.swing(pendulum.id, force: 0.5)
      expect(result).to eq(pendulum)
    end

    it 'updates position on the pendulum' do
      engine.swing(pendulum.id, force: 0.6)
      expect(pendulum.current_position).to eq(0.6)
    end

    it 'returns nil for unknown id' do
      expect(engine.swing('no-such-id', force: 0.1)).to be_nil
    end
  end

  describe '#damp_all!' do
    it 'damps every pendulum' do
      p1 = engine.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.8)
      p2 = engine.create_pendulum(pole_pair: :focus_diffusion, amplitude: 0.6)
      engine.damp_all!
      expect(p1.amplitude).to be < 0.8
      expect(p2.amplitude).to be < 0.6
    end

    it 'does nothing with no pendulums' do
      expect { engine.damp_all! }.not_to raise_error
    end
  end

  describe '#check_resonance' do
    it 'returns ids of resonant pendulums' do
      p = engine.create_pendulum(pole_pair: :analysis_intuition, period: 10.0)
      natural = 1.0 / 10.0
      result = engine.check_resonance(natural)
      expect(result).to include(p.id)
    end

    it 'returns empty array when no resonance' do
      engine.create_pendulum(pole_pair: :analysis_intuition, period: 10.0)
      expect(engine.check_resonance(99.0)).to be_empty
    end

    it 'returns empty array for zero or negative frequency' do
      engine.create_pendulum(pole_pair: :analysis_intuition, period: 10.0)
      expect(engine.check_resonance(0.0)).to be_empty
    end
  end

  describe '#dominant_pole' do
    let!(:pendulum) { engine.create_pendulum(pole_pair: :certainty_doubt) }

    it 'returns :neutral at center' do
      expect(engine.dominant_pole(pendulum.id)).to eq(:neutral)
    end

    it 'returns the correct pole after swinging' do
      engine.swing(pendulum.id, force: 0.9)
      expect(engine.dominant_pole(pendulum.id)).to eq(:doubt)
    end

    it 'returns nil for unknown id' do
      expect(engine.dominant_pole('missing-id')).to be_nil
    end
  end

  describe '#most_active' do
    before do
      engine.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.9)
      engine.create_pendulum(pole_pair: :focus_diffusion, amplitude: 0.3)
      engine.create_pendulum(pole_pair: :analysis_intuition, amplitude: 0.6)
    end

    it 'returns pendulums sorted by amplitude descending' do
      result = engine.most_active(limit: 3)
      amplitudes = result.map(&:amplitude)
      expect(amplitudes).to eq(amplitudes.sort.reverse)
    end

    it 'respects limit' do
      expect(engine.most_active(limit: 2).size).to eq(2)
    end

    it 'returns all if limit exceeds count' do
      expect(engine.most_active(limit: 10).size).to eq(3)
    end
  end

  describe '#most_damped' do
    before do
      engine.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.1)
      engine.create_pendulum(pole_pair: :focus_diffusion, amplitude: 0.8)
      engine.create_pendulum(pole_pair: :analysis_intuition, amplitude: 0.4)
    end

    it 'returns pendulums sorted by amplitude ascending' do
      result = engine.most_damped(limit: 3)
      amplitudes = result.map(&:amplitude)
      expect(amplitudes).to eq(amplitudes.sort)
    end

    it 'respects limit' do
      expect(engine.most_damped(limit: 1).size).to eq(1)
    end
  end

  describe '#pendulum_report' do
    before do
      engine.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.8)
      engine.create_pendulum(pole_pair: :certainty_doubt, amplitude: 0.5)
      engine.create_pendulum(pole_pair: :focus_diffusion, amplitude: 0.3)
    end

    it 'includes total count' do
      expect(engine.pendulum_report[:total]).to eq(3)
    end

    it 'includes max constant' do
      expect(engine.pendulum_report[:max]).to eq(Legion::Extensions::Agentic::Homeostasis::Pendulum::Helpers::Constants::MAX_PENDULUMS)
    end

    it 'groups pendulums by pole_pair' do
      report = engine.pendulum_report
      expect(report[:pole_pairs][:certainty_doubt]).to eq(2)
      expect(report[:pole_pairs][:focus_diffusion]).to eq(1)
    end

    it 'includes most_active as hashes' do
      report = engine.pendulum_report
      expect(report[:most_active]).to be_an(Array)
      expect(report[:most_active].first).to be_a(Hash)
    end

    it 'includes most_damped as hashes' do
      report = engine.pendulum_report
      expect(report[:most_damped]).to be_an(Array)
    end
  end

  describe '#get' do
    it 'returns the pendulum by id' do
      p = engine.create_pendulum(pole_pair: :approach_avoidance)
      expect(engine.get(p.id)).to eq(p)
    end

    it 'returns nil for unknown id' do
      expect(engine.get('not-here')).to be_nil
    end
  end
end
