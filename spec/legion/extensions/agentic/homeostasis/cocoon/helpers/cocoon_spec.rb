# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Cocoon::Helpers::Cocoon do
  subject(:cocoon) do
    described_class.new(cocoon_type: :chrysalis, domain: :cognitive, content: 'a fragile idea')
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(cocoon.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores cocoon_type as symbol' do
      expect(cocoon.cocoon_type).to eq(:chrysalis)
    end

    it 'stores domain as symbol' do
      expect(cocoon.domain).to eq(:cognitive)
    end

    it 'stores content' do
      expect(cocoon.content).to eq('a fragile idea')
    end

    it 'starts with zero maturity by default' do
      expect(cocoon.maturity).to eq(0.0)
    end

    it 'assigns protection from PROTECTION_BY_TYPE for chrysalis' do
      expect(cocoon.protection).to eq(0.8)
    end

    it 'starts in encapsulating stage' do
      expect(cocoon.stage).to eq(:encapsulating)
    end

    it 'records created_at as utc' do
      expect(cocoon.created_at).to be_a(Time)
    end

    it 'clamps maturity to 0..1 when overridden' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, maturity: 1.5)
      expect(c.maturity).to eq(1.0)
    end

    it 'clamps protection to 0..1 when overridden' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, protection: 2.0)
      expect(c.protection).to eq(1.0)
    end

    it 'uses fallback protection of 0.7 for unknown type via fetch default' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, protection: 0.7)
      expect(c.protection).to eq(0.7)
    end

    it 'assigns silk protection correctly' do
      c = described_class.new(cocoon_type: :silk, domain: :semantic)
      expect(c.protection).to eq(0.6)
    end

    it 'assigns shell protection correctly' do
      c = described_class.new(cocoon_type: :shell, domain: :semantic)
      expect(c.protection).to eq(0.9)
    end

    it 'assigns pod protection correctly' do
      c = described_class.new(cocoon_type: :pod, domain: :semantic)
      expect(c.protection).to eq(0.7)
    end

    it 'assigns web protection correctly' do
      c = described_class.new(cocoon_type: :web, domain: :semantic)
      expect(c.protection).to eq(0.5)
    end

    it 'enters developing stage when maturity starts at 0.5' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, maturity: 0.5)
      expect(c.stage).to eq(:developing)
    end

    it 'enters transforming stage when maturity starts at 0.8' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, maturity: 0.8)
      expect(c.stage).to eq(:transforming)
    end

    it 'enters ready stage when maturity starts at 1.0' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, maturity: 1.0)
      expect(c.stage).to eq(:ready)
    end
  end

  describe '#gestate!' do
    it 'increases maturity by MATURITY_RATE by default' do
      cocoon.gestate!
      expect(cocoon.maturity).to be_within(0.001).of(0.1)
    end

    it 'accepts a custom rate' do
      cocoon.gestate!(0.2)
      expect(cocoon.maturity).to be_within(0.001).of(0.2)
    end

    it 'does not exceed maturity 1.0' do
      20.times { cocoon.gestate! }
      expect(cocoon.maturity).to eq(1.0)
    end

    it 'transitions to developing stage' do
      4.times { cocoon.gestate!(0.1) }
      expect(cocoon.stage).to eq(:developing)
    end

    it 'transitions to transforming stage' do
      8.times { cocoon.gestate!(0.1) }
      expect(cocoon.stage).to eq(:transforming)
    end

    it 'transitions to ready stage at 1.0' do
      10.times { cocoon.gestate!(0.1) }
      expect(cocoon.stage).to eq(:ready)
    end

    it 'returns self for chaining' do
      expect(cocoon.gestate!).to be(cocoon)
    end

    it 'does not advance an emerged cocoon' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, maturity: 1.0)
      c.emerge!
      before_maturity = c.maturity
      c.gestate!
      expect(c.maturity).to eq(before_maturity)
    end
  end

  describe '#ready?' do
    it 'returns false for a new cocoon' do
      expect(cocoon).not_to be_ready
    end

    it 'returns true when maturity reaches 1.0' do
      10.times { cocoon.gestate!(0.1) }
      expect(cocoon).to be_ready
    end
  end

  describe '#premature?' do
    it 'returns true for a new cocoon' do
      expect(cocoon).to be_premature
    end

    it 'returns false once cocoon is ready' do
      10.times { cocoon.gestate!(0.1) }
      expect(cocoon).not_to be_premature
    end

    it 'returns false after emergence' do
      c = described_class.new(cocoon_type: :silk, domain: :emotional, maturity: 1.0)
      c.emerge!
      expect(c).not_to be_premature
    end
  end

  describe '#emerge!' do
    context 'when ready' do
      before { 10.times { cocoon.gestate!(0.1) } }

      it 'returns success true' do
        expect(cocoon.emerge![:success]).to be true
      end

      it 'returns the content' do
        expect(cocoon.emerge![:content]).to eq('a fragile idea')
      end

      it 'reports not damaged' do
        expect(cocoon.emerge![:damaged]).to be false
      end

      it 'sets stage to emerged' do
        cocoon.emerge!
        expect(cocoon.stage).to eq(:emerged)
      end
    end

    context 'when not ready' do
      it 'returns success false' do
        expect(cocoon.emerge![:success]).to be false
      end

      it 'reports not damaged' do
        expect(cocoon.emerge![:damaged]).to be false
      end

      it 'returns an error message' do
        expect(cocoon.emerge![:error]).to eq('not ready')
      end

      it 'does not change the stage' do
        cocoon.emerge!
        expect(cocoon.stage).to eq(:encapsulating)
      end
    end
  end

  describe '#expose!' do
    context 'when premature' do
      it 'returns success true' do
        expect(cocoon.expose![:success]).to be true
      end

      it 'reports the idea is damaged' do
        expect(cocoon.expose![:damaged]).to be true
      end

      it 'sets stage to emerged' do
        cocoon.expose!
        expect(cocoon.stage).to eq(:emerged)
      end

      it 'applies the premature penalty to maturity' do
        cocoon.gestate!(0.4)
        cocoon.expose!
        expect(cocoon.maturity).to be_within(0.001).of(0.4 * 0.5)
      end
    end

    context 'when ready' do
      before { 10.times { cocoon.gestate!(0.1) } }

      it 'returns success true' do
        expect(cocoon.expose![:success]).to be true
      end

      it 'reports not damaged' do
        expect(cocoon.expose![:damaged]).to be false
      end

      it 'sets stage to emerged' do
        cocoon.expose!
        expect(cocoon.stage).to eq(:emerged)
      end
    end
  end

  describe '#age_seconds' do
    it 'returns a non-negative float' do
      expect(cocoon.age_seconds).to be >= 0.0
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = cocoon.to_h
      expect(h).to include(
        :id, :cocoon_type, :domain, :content, :maturity, :stage,
        :protection, :ready, :premature, :maturity_label, :age_seconds, :created_at
      )
    end

    it 'includes the correct cocoon_type' do
      expect(cocoon.to_h[:cocoon_type]).to eq(:chrysalis)
    end

    it 'includes the correct domain' do
      expect(cocoon.to_h[:domain]).to eq(:cognitive)
    end

    it 'includes maturity rounded to 10 decimal places' do
      cocoon.gestate!(0.123456789012)
      expect(cocoon.to_h[:maturity].to_s.split('.').last.length).to be <= 10
    end

    it 'includes the maturity_label' do
      expect(cocoon.to_h[:maturity_label]).to eq(:newly_formed)
    end

    it 'includes created_at as iso8601' do
      expect(cocoon.to_h[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
  end
end
