# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Cocoon::Helpers::Constants do
  describe 'GESTATION_STAGES' do
    it 'is an array of symbols' do
      expect(described_class::GESTATION_STAGES).to all(be_a(Symbol))
    end

    it 'contains the five expected stages' do
      expect(described_class::GESTATION_STAGES).to eq(%i[encapsulating developing transforming ready emerged])
    end

    it 'is frozen' do
      expect(described_class::GESTATION_STAGES).to be_frozen
    end
  end

  describe 'COCOON_TYPES' do
    it 'is an array of symbols' do
      expect(described_class::COCOON_TYPES).to all(be_a(Symbol))
    end

    it 'contains the five expected types' do
      expect(described_class::COCOON_TYPES).to eq(%i[silk chrysalis shell pod web])
    end

    it 'is frozen' do
      expect(described_class::COCOON_TYPES).to be_frozen
    end
  end

  describe 'MAX_COCOONS' do
    it 'equals 100' do
      expect(described_class::MAX_COCOONS).to eq(100)
    end
  end

  describe 'MATURITY_RATE' do
    it 'equals 0.1' do
      expect(described_class::MATURITY_RATE).to eq(0.1)
    end
  end

  describe 'PREMATURE_PENALTY' do
    it 'equals 0.5' do
      expect(described_class::PREMATURE_PENALTY).to eq(0.5)
    end
  end

  describe 'PROTECTION_BY_TYPE' do
    it 'has an entry for every cocoon type' do
      described_class::COCOON_TYPES.each do |type|
        expect(described_class::PROTECTION_BY_TYPE).to have_key(type)
      end
    end

    it 'assigns highest protection to shell' do
      expect(described_class::PROTECTION_BY_TYPE[:shell]).to eq(0.9)
    end

    it 'assigns lowest protection to web' do
      expect(described_class::PROTECTION_BY_TYPE[:web]).to eq(0.5)
    end
  end

  describe 'MATURITY_LABELS' do
    it 'is a hash' do
      expect(described_class::MATURITY_LABELS).to be_a(Hash)
    end

    it 'is frozen' do
      expect(described_class::MATURITY_LABELS).to be_frozen
    end
  end

  describe '.label_for' do
    it 'returns fully_gestated for maturity 0.95' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.95)).to eq(:fully_gestated)
    end

    it 'returns nearly_ready for maturity 0.8' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.8)).to eq(:nearly_ready)
    end

    it 'returns mid_gestation for maturity 0.6' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.6)).to eq(:mid_gestation)
    end

    it 'returns early_gestation for maturity 0.4' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.4)).to eq(:early_gestation)
    end

    it 'returns just_encapsulated for maturity 0.2' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.2)).to eq(:just_encapsulated)
    end

    it 'returns newly_formed for maturity 0.05' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.05)).to eq(:newly_formed)
    end

    it 'returns unknown for an empty hash' do
      expect(described_class.label_for({}, 0.5)).to eq(:unknown)
    end
  end
end
