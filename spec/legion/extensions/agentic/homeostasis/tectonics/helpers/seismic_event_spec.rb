# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::SeismicEvent do
  let(:plate_id) { 'plate-abc-123' }

  describe '#initialize' do
    subject(:event) do
      described_class.new(type: :earthquake, magnitude: 3.5, epicenter_plate_id: plate_id)
    end

    it 'generates a UUID id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets type' do
      expect(event.type).to eq(:earthquake)
    end

    it 'sets magnitude' do
      expect(event.magnitude).to eq(3.5)
    end

    it 'sets epicenter_plate_id' do
      expect(event.epicenter_plate_id).to eq(plate_id)
    end

    it 'defaults affected_plate_ids to empty array' do
      expect(event.affected_plate_ids).to eq([])
    end

    it 'records timestamp' do
      expect(event.timestamp).to be_a(Time)
    end

    it 'raises ArgumentError for unknown type' do
      expect do
        described_class.new(type: :explosion, magnitude: 1.0, epicenter_plate_id: plate_id)
      end.to raise_error(ArgumentError, /unknown event type/)
    end

    it 'clamps negative magnitude to 0' do
      e = described_class.new(type: :tremor, magnitude: -1.0, epicenter_plate_id: plate_id)
      expect(e.magnitude).to eq(0.0)
    end
  end

  describe 'with affected plates and parent' do
    subject(:aftershock) do
      described_class.new(
        type:               :aftershock,
        magnitude:          1.2,
        epicenter_plate_id: plate_id,
        affected_plate_ids: %w[p1 p2],
        parent_event_id:    'parent-123'
      )
    end

    it 'stores affected_plate_ids' do
      expect(aftershock.affected_plate_ids).to eq(%w[p1 p2])
    end

    it 'stores parent_event_id' do
      expect(aftershock.parent_event_id).to eq('parent-123')
    end

    it 'reports aftershock?' do
      expect(aftershock.aftershock?).to be(true)
    end
  end

  describe '#aftershock?' do
    it 'returns false for earthquake type' do
      e = described_class.new(type: :earthquake, magnitude: 2.0, epicenter_plate_id: plate_id)
      expect(e.aftershock?).to be(false)
    end

    it 'returns false for tremor type' do
      e = described_class.new(type: :tremor, magnitude: 0.5, epicenter_plate_id: plate_id)
      expect(e.aftershock?).to be(false)
    end
  end

  describe '#label' do
    it 'returns :micro for magnitude < 1.0' do
      e = described_class.new(type: :tremor, magnitude: 0.5, epicenter_plate_id: plate_id)
      expect(e.label).to eq(:micro)
    end

    it 'returns :great for magnitude >= 5.0' do
      e = described_class.new(type: :earthquake, magnitude: 5.0, epicenter_plate_id: plate_id)
      expect(e.label).to eq(:great)
    end

    it 'returns :moderate for magnitude 3.0..4.0' do
      e = described_class.new(type: :earthquake, magnitude: 3.5, epicenter_plate_id: plate_id)
      expect(e.label).to eq(:moderate)
    end
  end

  describe '#to_h' do
    subject(:event) do
      described_class.new(type: :earthquake, magnitude: 2.0, epicenter_plate_id: plate_id,
                          affected_plate_ids: ['other'])
    end

    it 'includes all expected keys' do
      h = event.to_h
      expect(h.keys).to include(:id, :type, :magnitude, :label, :epicenter_plate_id,
                                :affected_plate_ids, :parent_event_id, :timestamp)
    end

    it 'includes computed label' do
      expect(event.to_h[:label]).to eq(:light)
    end

    it 'parent_event_id is nil when not set' do
      expect(event.to_h[:parent_event_id]).to be_nil
    end
  end
end
