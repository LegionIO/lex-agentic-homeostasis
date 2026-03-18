# frozen_string_literal: true

require 'legion/extensions/agentic/homeostasis/tempo/client'

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tempo::Runners::Tempo do
  let(:client) { Legion::Extensions::Agentic::Homeostasis::Tempo::Client.new }

  describe '#set_tempo_baseline' do
    it 'returns domain and baseline' do
      result = client.set_tempo_baseline(domain: :analysis, tempo: 0.4)
      expect(result[:domain]).to eq(:analysis)
      expect(result[:baseline]).to eq(0.4)
    end
  end

  describe '#record_tempo' do
    it 'returns a hash with tempo record fields' do
      result = client.record_tempo(domain: :code, current_tempo: 0.6, task_requirement: 0.8)
      expect(result).to include(:id, :domain, :current_tempo, :mismatch, :tempo_label, :mismatch_label)
    end

    it 'computes mismatch correctly' do
      result = client.record_tempo(domain: :code, current_tempo: 0.6, task_requirement: 0.8)
      expect(result[:mismatch]).to be_within(0.001).of(0.2)
    end

    it 'assigns :slightly_off mismatch label for 0.2 gap' do
      result = client.record_tempo(domain: :code, current_tempo: 0.6, task_requirement: 0.8)
      expect(result[:mismatch_label]).to eq(:slightly_off)
    end

    it 'assigns :synchronized label for identical tempos' do
      result = client.record_tempo(domain: :code, current_tempo: 0.5, task_requirement: 0.5)
      expect(result[:mismatch_label]).to eq(:synchronized)
    end
  end

  describe '#adapt_tempo' do
    it 'returns adapted: false when no records exist' do
      result = client.adapt_tempo(domain: :nonexistent, target: 0.8)
      expect(result[:adapted]).to be false
    end

    it 'adapts and returns adapted: true when records exist' do
      client.record_tempo(domain: :code, current_tempo: 0.3, task_requirement: 0.6)
      result = client.adapt_tempo(domain: :code, target: 0.8)
      expect(result[:adapted]).to be true
      expect(result[:current_tempo]).to be > 0.3
    end
  end

  describe '#tempo_status' do
    it 'returns found: false for unknown domain' do
      result = client.tempo_status(domain: :unknown)
      expect(result[:found]).to be false
    end

    it 'returns found: true for a recorded domain' do
      client.record_tempo(domain: :ops, current_tempo: 0.5, task_requirement: 0.5)
      result = client.tempo_status(domain: :ops)
      expect(result[:found]).to be true
    end

    it 'returns a full report when no domain given' do
      result = client.tempo_status
      expect(result).to include(:domains, :average_mismatch, :in_sync, :mismatched, :total_records)
    end
  end

  describe '#domains_in_sync' do
    it 'returns an empty list when nothing recorded' do
      result = client.domains_in_sync
      expect(result[:count]).to eq(0)
    end

    it 'includes a synchronized domain' do
      client.record_tempo(domain: :infra, current_tempo: 0.5, task_requirement: 0.52)
      result = client.domains_in_sync
      expect(result[:domains]).to include(:infra)
    end
  end

  describe '#domains_mismatched' do
    it 'returns an empty list when nothing recorded' do
      result = client.domains_mismatched
      expect(result[:count]).to eq(0)
    end

    it 'includes a mismatched domain' do
      client.record_tempo(domain: :infra, current_tempo: 0.1, task_requirement: 0.9)
      result = client.domains_mismatched
      expect(result[:domains]).to include(:infra)
    end
  end

  describe '#tempo_report' do
    it 'returns all report keys' do
      result = client.tempo_report
      expect(result).to include(:domains, :average_mismatch, :in_sync, :mismatched, :total_records)
    end

    it 'reflects accumulated records' do
      client.record_tempo(domain: :a, current_tempo: 0.5, task_requirement: 0.5)
      client.record_tempo(domain: :b, current_tempo: 0.7, task_requirement: 0.9)
      report = client.tempo_report
      expect(report[:total_records]).to eq(2)
      expect(report[:domains]).to include(:a, :b)
    end
  end
end
