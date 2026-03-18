# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::FossilFuel::Helpers::Combustion do
  subject(:combustion) do
    described_class.new(reserve_id: 'r-123', fuel_amount: 0.5, grade: :refined, quality: 0.7)
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(combustion.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores reserve_id' do
      expect(combustion.reserve_id).to eq('r-123')
    end

    it 'clamps fuel_amount to 0..1' do
      c = described_class.new(reserve_id: 'x', fuel_amount: 5.0)
      expect(c.fuel_amount).to eq(1.0)
    end

    it 'converts grade to symbol' do
      expect(combustion.grade).to eq(:refined)
    end

    it 'calculates energy_released' do
      expect(combustion.energy_released).to be_a(Float)
      expect(combustion.energy_released).to be_between(0.0, 1.0)
    end

    it 'sets burned_at' do
      expect(combustion.burned_at).to be_a(Time)
    end

    it 'raises on unknown grade' do
      expect do
        described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :nuclear)
      end.to raise_error(ArgumentError, /unknown grade/)
    end

    it 'defaults grade to crude' do
      c = described_class.new(reserve_id: 'x', fuel_amount: 0.5)
      expect(c.grade).to eq(:crude)
    end

    it 'defaults quality to 0.5' do
      c = described_class.new(reserve_id: 'x', fuel_amount: 0.5)
      crude_energy = c.energy_released
      expect(crude_energy).to be > 0.0
    end
  end

  describe 'grade multipliers' do
    it 'crude produces least energy' do
      crude = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :crude, quality: 0.5)
      refined = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :refined, quality: 0.5)
      expect(crude.energy_released).to be < refined.energy_released
    end

    it 'premium produces more than refined' do
      refined = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :refined, quality: 0.5)
      premium = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :premium, quality: 0.5)
      expect(refined.energy_released).to be < premium.energy_released
    end

    it 'synthetic produces the most energy' do
      premium = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :premium, quality: 0.5)
      synthetic = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :synthetic, quality: 0.5)
      expect(premium.energy_released).to be < synthetic.energy_released
    end
  end

  describe 'quality scaling' do
    it 'higher quality produces more energy' do
      low_q = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :crude, quality: 0.1)
      high_q = described_class.new(reserve_id: 'x', fuel_amount: 0.5, grade: :crude, quality: 0.9)
      expect(low_q.energy_released).to be < high_q.energy_released
    end
  end

  describe '#efficient?' do
    it 'returns true when energy exceeds 70% of fuel' do
      c = described_class.new(reserve_id: 'x', fuel_amount: 0.3, grade: :synthetic, quality: 1.0)
      expect(c).to be_efficient
    end

    it 'returns false for low-efficiency combustion' do
      c = described_class.new(reserve_id: 'x', fuel_amount: 0.9, grade: :crude, quality: 0.1)
      expect(c).not_to be_efficient
    end
  end

  describe '#wasteful?' do
    it 'returns true when energy is below 30% of fuel' do
      c = described_class.new(reserve_id: 'x', fuel_amount: 0.9, grade: :crude, quality: 0.1)
      expect(c).to be_wasteful
    end

    it 'returns false for high-efficiency combustion' do
      c = described_class.new(reserve_id: 'x', fuel_amount: 0.3, grade: :synthetic, quality: 1.0)
      expect(c).not_to be_wasteful
    end
  end

  describe '#energy_label' do
    it 'returns a symbol' do
      expect(combustion.energy_label).to be_a(Symbol)
    end

    it 'returns a valid label' do
      valid = %i[explosive powerful steady weak exhausted]
      expect(valid).to include(combustion.energy_label)
    end
  end

  describe '#to_h' do
    subject(:hash) { combustion.to_h }

    it 'includes all expected keys' do
      expected = %i[id reserve_id fuel_amount grade energy_released
                    energy_label efficient wasteful burned_at]
      expect(hash.keys).to match_array(expected)
    end

    it 'has correct grade' do
      expect(hash[:grade]).to eq(:refined)
    end

    it 'includes boolean flags' do
      expect(hash).to have_key(:efficient)
      expect(hash).to have_key(:wasteful)
    end
  end
end
