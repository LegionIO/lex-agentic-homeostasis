# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::OscillationNetwork do
  subject(:net) { described_class.new }

  let(:constants) { Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::Constants }

  def setup_pair
    net.add_oscillator(id: :visual, domain: :perception)
    net.add_oscillator(id: :auditory, domain: :perception)
  end

  describe '#add_oscillator' do
    it 'adds an oscillator' do
      osc = net.add_oscillator(id: :visual)
      expect(osc).to be_a(Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::Oscillator)
      expect(net.oscillators.size).to eq(1)
    end

    it 'returns existing on duplicate' do
      first = net.add_oscillator(id: :visual)
      second = net.add_oscillator(id: :visual)
      expect(second).to equal(first)
    end

    it 'enforces MAX_OSCILLATORS' do
      constants::MAX_OSCILLATORS.times { |i| net.add_oscillator(id: :"osc_#{i}") }
      expect(net.add_oscillator(id: :overflow)).to be_nil
    end
  end

  describe '#activate_band' do
    it 'activates a band on an oscillator' do
      net.add_oscillator(id: :visual)
      osc = net.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.6)
      expect(osc.power(:gamma)).to eq(0.6)
    end

    it 'returns nil for unknown oscillator' do
      expect(net.activate_band(oscillator_id: :nope, band: :gamma)).to be_nil
    end

    it 'propagates to coupled oscillators' do
      setup_pair
      net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      # strengthen coupling so propagation is measurable
      5.times { net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma) }
      net.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.8)
      expect(net.oscillators[:auditory].power(:gamma)).to be > 0
    end
  end

  describe '#suppress_band' do
    it 'suppresses power' do
      net.add_oscillator(id: :visual)
      net.activate_band(oscillator_id: :visual, band: :alpha, amount: 0.5)
      net.suppress_band(oscillator_id: :visual, band: :alpha, amount: 0.3)
      expect(net.oscillators[:visual].power(:alpha)).to be_within(0.01).of(0.2)
    end
  end

  describe '#couple' do
    it 'creates a coupling between two oscillators' do
      setup_pair
      c = net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      expect(c).to be_a(Legion::Extensions::Agentic::Homeostasis::NeuralOscillation::Helpers::Coupling)
      expect(net.couplings.size).to eq(1)
    end

    it 'strengthens existing coupling on duplicate' do
      setup_pair
      first = net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      before = first.strength
      net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      expect(first.strength).to be > before
    end

    it 'returns nil for self-coupling' do
      net.add_oscillator(id: :visual)
      expect(net.couple(oscillator_a: :visual, oscillator_b: :visual, band: :gamma)).to be_nil
    end

    it 'returns nil for unknown oscillators' do
      expect(net.couple(oscillator_a: :nope, oscillator_b: :also_nope, band: :gamma)).to be_nil
    end

    it 'enforces MAX_COUPLINGS' do
      constants::MAX_OSCILLATORS.times { |i| net.add_oscillator(id: :"o_#{i}") }
      (constants::MAX_COUPLINGS + 5).times do |i|
        a = :"o_#{i % constants::MAX_OSCILLATORS}"
        b = :"o_#{(i + 1) % constants::MAX_OSCILLATORS}"
        band = constants::BANDS[i % constants::BANDS.size]
        net.couple(oscillator_a: a, oscillator_b: b, band: band)
      end
      expect(net.couplings.size).to be <= constants::MAX_COUPLINGS
    end
  end

  describe '#decouple' do
    it 'removes a coupling' do
      setup_pair
      net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      expect(net.decouple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)).to be true
      expect(net.couplings).to be_empty
    end

    it 'returns false for nonexistent coupling' do
      expect(net.decouple(oscillator_a: :nope, oscillator_b: :also, band: :gamma)).to be false
    end
  end

  describe '#global_rhythm' do
    it 'returns nil when no oscillators' do
      expect(net.global_rhythm).to be_nil
    end

    it 'returns the dominant band across the network' do
      net.add_oscillator(id: :visual)
      net.add_oscillator(id: :auditory)
      net.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.8)
      net.activate_band(oscillator_id: :auditory, band: :gamma, amount: 0.7)
      expect(net.global_rhythm).to eq(:gamma)
    end
  end

  describe '#cognitive_state' do
    it 'returns :idle when no rhythm' do
      expect(net.cognitive_state).to eq(:idle)
    end

    it 'maps gamma to :integrating' do
      net.add_oscillator(id: :visual)
      net.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.9)
      expect(net.cognitive_state).to eq(:integrating)
    end

    it 'maps beta to :focused' do
      net.add_oscillator(id: :prefrontal)
      net.activate_band(oscillator_id: :prefrontal, band: :beta, amount: 0.9)
      expect(net.cognitive_state).to eq(:focused)
    end

    it 'maps theta to :encoding' do
      net.add_oscillator(id: :hippocampus)
      net.activate_band(oscillator_id: :hippocampus, band: :theta, amount: 0.9)
      expect(net.cognitive_state).to eq(:encoding)
    end

    it 'maps alpha to :resting' do
      net.add_oscillator(id: :occipital)
      net.activate_band(oscillator_id: :occipital, band: :alpha, amount: 0.9)
      expect(net.cognitive_state).to eq(:resting)
    end
  end

  describe '#synchrony_for' do
    it 'returns 0 with no synchronized couplings' do
      expect(net.synchrony_for(band: :gamma)).to eq(0.0)
    end

    it 'returns positive when couplings are synchronized' do
      setup_pair
      c = net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      c.strength = constants::SYNC_THRESHOLD + 0.2
      expect(net.synchrony_for(band: :gamma)).to be > 0
    end
  end

  describe '#network_synchrony' do
    it 'returns 0 with no couplings' do
      expect(net.network_synchrony).to eq(0.0)
    end
  end

  describe '#desynchronize' do
    it 'weakens couplings in the specified band' do
      setup_pair
      c = net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :alpha)
      c.strength = 0.8
      net.desynchronize(band: :alpha)
      expect(c.strength).to be < 0.8
    end

    it 'suppresses oscillator power in the band' do
      net.add_oscillator(id: :visual)
      net.activate_band(oscillator_id: :visual, band: :alpha, amount: 0.5)
      net.desynchronize(band: :alpha)
      expect(net.oscillators[:visual].power(:alpha)).to be < 0.5
    end
  end

  describe '#tick' do
    it 'decays power and removes weak couplings' do
      setup_pair
      net.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.5)
      c = net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      c.strength = constants::COUPLING_FLOOR + constants::COUPLING_DECAY
      before_power = net.oscillators[:visual].power(:gamma)
      net.tick
      expect(net.oscillators[:visual].power(:gamma)).to be < before_power
      expect(net.couplings).to be_empty
    end

    it 'advances phases' do
      net.add_oscillator(id: :visual)
      net.activate_band(oscillator_id: :visual, band: :beta, amount: 0.5)
      before = net.oscillators[:visual].phase(:beta)
      net.tick
      expect(net.oscillators[:visual].phase(:beta)).not_to eq(before)
    end
  end

  describe '#oscillators_in_band' do
    it 'returns oscillators whose dominant band matches' do
      net.add_oscillator(id: :visual)
      net.add_oscillator(id: :motor)
      net.activate_band(oscillator_id: :visual, band: :gamma, amount: 0.8)
      net.activate_band(oscillator_id: :motor, band: :beta, amount: 0.8)
      results = net.oscillators_in_band(band: :gamma)
      expect(results.size).to eq(1)
      expect(results.first[:id]).to eq(:visual)
    end
  end

  describe '#couplings_for' do
    it 'returns couplings involving an oscillator' do
      setup_pair
      net.add_oscillator(id: :motor)
      net.couple(oscillator_a: :visual, oscillator_b: :auditory, band: :gamma)
      net.couple(oscillator_a: :visual, oscillator_b: :motor, band: :beta)
      results = net.couplings_for(oscillator_id: :visual)
      expect(results.size).to eq(2)
    end
  end

  describe '#to_h' do
    it 'returns summary hash' do
      h = net.to_h
      expect(h).to include(:oscillator_count, :coupling_count, :global_rhythm,
                           :cognitive_state, :network_synchrony, :band_powers, :history_size)
    end
  end
end
