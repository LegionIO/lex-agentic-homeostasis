# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tempo::Helpers::TempoEngine do
  let(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts with empty records' do
      expect(engine.records).to be_empty
    end

    it 'starts with empty domain_baselines' do
      expect(engine.domain_baselines).to be_empty
    end
  end

  describe '#set_baseline' do
    it 'stores the baseline for a domain' do
      engine.set_baseline(domain: :analysis, tempo: 0.4)
      expect(engine.domain_baselines[:analysis]).to eq(0.4)
    end

    it 'clamps baseline to [0.0, 1.0]' do
      engine.set_baseline(domain: :analysis, tempo: 1.5)
      expect(engine.domain_baselines[:analysis]).to eq(1.0)
    end
  end

  describe '#record_tempo' do
    it 'returns a TempoRecord' do
      result = engine.record_tempo(domain: :code, current_tempo: 0.6, task_requirement: 0.5)
      expect(result).to be_a(Legion::Extensions::Agentic::Homeostasis::Tempo::Helpers::TempoRecord)
    end

    it 'stores the record under the domain' do
      engine.record_tempo(domain: :code, current_tempo: 0.6, task_requirement: 0.5)
      expect(engine.records[:code].size).to eq(1)
    end

    it 'uses the set baseline when one exists' do
      engine.set_baseline(domain: :code, tempo: 0.3)
      record = engine.record_tempo(domain: :code, current_tempo: 0.6, task_requirement: 0.5)
      expect(record.baseline_tempo).to eq(0.3)
    end

    it 'uses DEFAULT_TEMPO as baseline when none set' do
      record = engine.record_tempo(domain: :code, current_tempo: 0.6, task_requirement: 0.5)
      expect(record.baseline_tempo).to eq(
        Legion::Extensions::Agentic::Homeostasis::Tempo::Helpers::Constants::DEFAULT_TEMPO
      )
    end

    it 'trims records at MAX_TEMPO_RECORDS' do
      max = Legion::Extensions::Agentic::Homeostasis::Tempo::Helpers::Constants::MAX_TEMPO_RECORDS
      (max + 10).times { engine.record_tempo(domain: :code, current_tempo: 0.5, task_requirement: 0.5) }
      expect(engine.records[:code].size).to eq(max)
    end
  end

  describe '#adapt_tempo' do
    it 'returns nil when no records exist for domain' do
      expect(engine.adapt_tempo(domain: :nonexistent, target: 0.7)).to be_nil
    end

    it 'adapts the latest record toward the target' do
      engine.record_tempo(domain: :code, current_tempo: 0.3, task_requirement: 0.5)
      result = engine.adapt_tempo(domain: :code, target: 0.8)
      expect(result.current_tempo).to be > 0.3
    end

    it 'returns the updated TempoRecord' do
      engine.record_tempo(domain: :code, current_tempo: 0.3, task_requirement: 0.5)
      result = engine.adapt_tempo(domain: :code, target: 0.8)
      expect(result).to be_a(Legion::Extensions::Agentic::Homeostasis::Tempo::Helpers::TempoRecord)
    end
  end

  describe '#average_mismatch' do
    it 'returns 0.0 when no records exist' do
      expect(engine.average_mismatch).to eq(0.0)
    end

    it 'computes the mean mismatch across all records' do
      engine.record_tempo(domain: :a, current_tempo: 0.5, task_requirement: 0.5)
      engine.record_tempo(domain: :b, current_tempo: 0.3, task_requirement: 0.7)
      avg = engine.average_mismatch
      expect(avg).to be_within(0.001).of(0.2)
    end
  end

  describe '#domains_in_sync' do
    it 'returns empty when no domains recorded' do
      expect(engine.domains_in_sync).to be_empty
    end

    it 'includes domains where latest mismatch <= 0.1' do
      engine.record_tempo(domain: :a, current_tempo: 0.5, task_requirement: 0.55)
      expect(engine.domains_in_sync).to include(:a)
    end

    it 'excludes domains where latest mismatch > 0.1' do
      engine.record_tempo(domain: :b, current_tempo: 0.2, task_requirement: 0.9)
      expect(engine.domains_in_sync).not_to include(:b)
    end
  end

  describe '#domains_mismatched' do
    it 'returns empty when no domains recorded' do
      expect(engine.domains_mismatched).to be_empty
    end

    it 'includes domains where latest mismatch > 0.1' do
      engine.record_tempo(domain: :b, current_tempo: 0.2, task_requirement: 0.9)
      expect(engine.domains_mismatched).to include(:b)
    end

    it 'excludes synchronized domains' do
      engine.record_tempo(domain: :a, current_tempo: 0.5, task_requirement: 0.55)
      expect(engine.domains_mismatched).not_to include(:a)
    end
  end

  describe '#tempo_report' do
    it 'returns a hash with expected keys' do
      report = engine.tempo_report
      expect(report).to include(:domains, :average_mismatch, :in_sync, :mismatched, :total_records)
    end

    it 'total_records counts all stored records' do
      engine.record_tempo(domain: :a, current_tempo: 0.5, task_requirement: 0.5)
      engine.record_tempo(domain: :a, current_tempo: 0.6, task_requirement: 0.5)
      engine.record_tempo(domain: :b, current_tempo: 0.4, task_requirement: 0.5)
      expect(engine.tempo_report[:total_records]).to eq(3)
    end
  end

  describe '#to_h' do
    it 'includes domain_baselines and records' do
      engine.set_baseline(domain: :code, tempo: 0.4)
      engine.record_tempo(domain: :code, current_tempo: 0.5, task_requirement: 0.6)
      h = engine.to_h
      expect(h).to have_key(:domain_baselines)
      expect(h).to have_key(:records)
      expect(h[:records][:code].first).to be_a(Hash)
    end
  end
end
