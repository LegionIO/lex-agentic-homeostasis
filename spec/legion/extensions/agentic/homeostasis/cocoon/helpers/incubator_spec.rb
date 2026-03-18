# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Cocoon::Helpers::Incubator do
  subject(:incubator) { described_class.new }

  let(:cocoon_type) { :chrysalis }
  let(:domain) { :cognitive }

  describe '#create_cocoon' do
    it 'returns a Cocoon instance' do
      cocoon = incubator.create_cocoon(cocoon_type: cocoon_type, domain: domain)
      expect(cocoon).to be_a(Legion::Extensions::Agentic::Homeostasis::Cocoon::Helpers::Cocoon)
    end

    it 'stores the cocoon in the incubator' do
      incubator.create_cocoon(cocoon_type: cocoon_type, domain: domain)
      report = incubator.incubator_report
      expect(report[:total_cocoons]).to eq(1)
    end

    it 'accepts content' do
      cocoon = incubator.create_cocoon(cocoon_type: :silk, domain: :emotional, content: 'idea')
      expect(cocoon.content).to eq('idea')
    end

    it 'accepts custom maturity' do
      cocoon = incubator.create_cocoon(cocoon_type: :silk, domain: :emotional, maturity: 0.5)
      expect(cocoon.maturity).to eq(0.5)
    end

    it 'accepts custom protection' do
      cocoon = incubator.create_cocoon(cocoon_type: :silk, domain: :emotional, protection: 0.4)
      expect(cocoon.protection).to eq(0.4)
    end

    it 'creates multiple distinct cocoons' do
      c1 = incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      c2 = incubator.create_cocoon(cocoon_type: :pod,  domain: :emotional)
      expect(c1.id).not_to eq(c2.id)
    end
  end

  describe '#gestate_all!' do
    before do
      incubator.create_cocoon(cocoon_type: :silk,  domain: :cognitive)
      incubator.create_cocoon(cocoon_type: :shell, domain: :emotional)
    end

    it 'advances all active cocoons' do
      incubator.gestate_all!
      report = incubator.incubator_report
      expect(report[:average_maturity]).to be > 0.0
    end

    it 'returns the incubator for chaining' do
      expect(incubator.gestate_all!).to be(incubator)
    end

    it 'accepts a custom rate' do
      incubator.gestate_all!(0.3)
      report = incubator.incubator_report
      expect(report[:average_maturity]).to be_within(0.001).of(0.3)
    end

    it 'does not advance emerged cocoons' do
      c = incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive, maturity: 1.0)
      c.emerge!
      before_mat = c.maturity
      incubator.gestate_all!
      expect(c.maturity).to eq(before_mat)
    end
  end

  describe '#harvest_ready' do
    it 'returns an empty array when nothing is ready' do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      expect(incubator.harvest_ready).to be_empty
    end

    it 'returns emerged results for ready cocoons' do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive, maturity: 1.0)
      results = incubator.harvest_ready
      expect(results.size).to eq(1)
      expect(results.first[:success]).to be true
    end

    it 'removes harvested cocoons from the incubator' do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive, maturity: 1.0)
      incubator.harvest_ready
      expect(incubator.incubator_report[:total_cocoons]).to eq(0)
    end

    it 'leaves unready cocoons in place' do
      incubator.create_cocoon(cocoon_type: :silk,  domain: :cognitive, maturity: 1.0)
      incubator.create_cocoon(cocoon_type: :shell, domain: :emotional, maturity: 0.3)
      incubator.harvest_ready
      expect(incubator.incubator_report[:total_cocoons]).to eq(1)
    end
  end

  describe '#force_emerge' do
    it 'returns success true for a valid id' do
      cocoon = incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      result = incubator.force_emerge(cocoon.id)
      expect(result[:success]).to be true
    end

    it 'returns success false for an unknown id' do
      result = incubator.force_emerge('nonexistent-id')
      expect(result[:success]).to be false
    end

    it 'returns not found error for unknown id' do
      result = incubator.force_emerge('bad-id')
      expect(result[:error]).to eq('cocoon not found')
    end

    it 'marks the cocoon as damaged when premature' do
      cocoon = incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive, maturity: 0.2)
      result = incubator.force_emerge(cocoon.id)
      expect(result[:damaged]).to be true
    end

    it 'removes the cocoon from the incubator after emergence' do
      cocoon = incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      incubator.force_emerge(cocoon.id)
      expect(incubator.incubator_report[:total_cocoons]).to eq(0)
    end
  end

  describe '#by_stage' do
    before do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      incubator.create_cocoon(cocoon_type: :pod,  domain: :cognitive, maturity: 0.5)
      incubator.create_cocoon(cocoon_type: :web,  domain: :emotional, maturity: 0.8)
    end

    it 'returns cocoons in encapsulating stage' do
      expect(incubator.by_stage(:encapsulating).size).to eq(1)
    end

    it 'returns cocoons in developing stage' do
      expect(incubator.by_stage(:developing).size).to eq(1)
    end

    it 'returns cocoons in transforming stage' do
      expect(incubator.by_stage(:transforming).size).to eq(1)
    end

    it 'returns empty array for an unused stage' do
      expect(incubator.by_stage(:emerged)).to be_empty
    end
  end

  describe '#most_mature' do
    before do
      incubator.create_cocoon(cocoon_type: :silk,  domain: :cognitive, maturity: 0.2)
      incubator.create_cocoon(cocoon_type: :shell, domain: :emotional, maturity: 0.8)
      incubator.create_cocoon(cocoon_type: :pod,   domain: :semantic,  maturity: 0.5)
    end

    it 'returns cocoons sorted by descending maturity' do
      results = incubator.most_mature(limit: 3)
      maturities = results.map(&:maturity)
      expect(maturities).to eq(maturities.sort.reverse)
    end

    it 'respects the limit' do
      expect(incubator.most_mature(limit: 2).size).to eq(2)
    end

    it 'returns the most mature first' do
      expect(incubator.most_mature(limit: 1).first.maturity).to eq(0.8)
    end
  end

  describe '#incubator_report' do
    it 'includes total_cocoons' do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      expect(incubator.incubator_report[:total_cocoons]).to eq(1)
    end

    it 'includes average_maturity of 0.0 for empty incubator' do
      expect(incubator.incubator_report[:average_maturity]).to eq(0.0)
    end

    it 'includes maturity_label' do
      expect(incubator.incubator_report).to have_key(:maturity_label)
    end

    it 'includes average_protection' do
      expect(incubator.incubator_report).to have_key(:average_protection)
    end

    it 'includes stage_distribution' do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      dist = incubator.incubator_report[:stage_distribution]
      expect(dist[:encapsulating]).to eq(1)
    end

    it 'includes ready_count' do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive, maturity: 1.0)
      expect(incubator.incubator_report[:ready_count]).to eq(1)
    end

    it 'includes most_mature array' do
      incubator.create_cocoon(cocoon_type: :silk, domain: :cognitive)
      expect(incubator.incubator_report[:most_mature]).to be_an(Array)
    end

    it 'includes all expected keys' do
      report = incubator.incubator_report
      expect(report).to include(
        :total_cocoons, :average_maturity, :maturity_label,
        :average_protection, :stage_distribution, :ready_count, :most_mature
      )
    end
  end

  describe '#to_h' do
    it 'returns total_cocoons and average_maturity' do
      h = incubator.to_h
      expect(h).to include(:total_cocoons, :average_maturity)
    end

    it 'returns 0 total and 0.0 average for empty incubator' do
      expect(incubator.to_h).to eq({ total_cocoons: 0, average_maturity: 0.0 })
    end
  end
end
