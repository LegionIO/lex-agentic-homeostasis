# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Hourglass do
  let(:hourglass) { described_class.new(domain: 'planning', grain_type: :attention) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(hourglass.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets domain as string' do
      expect(hourglass.domain).to eq('planning')
    end

    it 'sets grain_type as symbol' do
      expect(hourglass.grain_type).to eq(:attention)
    end

    it 'defaults top_level to 1.0' do
      expect(hourglass.top_level).to eq(1.0)
    end

    it 'defaults bottom_level to 0.0' do
      expect(hourglass.bottom_level).to eq(0.0)
    end

    it 'defaults neck_width to 0.5' do
      expect(hourglass.neck_width).to eq(0.5)
    end

    it 'starts in :full state when top=1.0 and bottom=0.0' do
      expect(hourglass.state).to eq(:full)
    end

    it 'accepts all valid grain_types' do
      Legion::Extensions::Agentic::Homeostasis::Hourglass::Helpers::Constants::GRAIN_TYPES.each do |type|
        expect { described_class.new(grain_type: type) }.not_to raise_error
      end
    end

    it 'raises ArgumentError for unknown grain_type' do
      expect { described_class.new(grain_type: :invalid) }.to raise_error(ArgumentError, /unknown grain_type/)
    end

    it 'raises ArgumentError for top_level out of range' do
      expect { described_class.new(top_level: 1.5) }.to raise_error(ArgumentError, /top_level/)
    end

    it 'raises ArgumentError for bottom_level out of range' do
      expect { described_class.new(bottom_level: -0.1) }.to raise_error(ArgumentError, /bottom_level/)
    end

    it 'raises ArgumentError for neck_width out of range' do
      expect { described_class.new(neck_width: 2.0) }.to raise_error(ArgumentError, /neck_width/)
    end

    it 'sets created_at as UTC time' do
      expect(hourglass.created_at).to be_a(Time)
    end

    it 'starts with flipped_at as nil' do
      expect(hourglass.flipped_at).to be_nil
    end
  end

  describe '#flow!' do
    it 'reduces top_level' do
      h = described_class.new(grain_type: :focus, top_level: 1.0, neck_width: 0.5)
      h.flow!(0.1)
      expect(h.top_level).to be < 1.0
    end

    it 'increases bottom_level' do
      h = described_class.new(grain_type: :focus, top_level: 1.0, neck_width: 0.5)
      h.flow!(0.1)
      expect(h.bottom_level).to be > 0.0
    end

    it 'scales flow by neck_width' do
      narrow = described_class.new(grain_type: :attention, top_level: 1.0, neck_width: 0.1)
      wide   = described_class.new(grain_type: :attention, top_level: 1.0, neck_width: 1.0)
      narrow.flow!(0.1)
      wide.flow!(0.1)
      expect(wide.top_level).to be < narrow.top_level
    end

    it 'does not flow when paused' do
      h = described_class.new(grain_type: :focus, top_level: 0.8)
      h.pause!
      h.flow!(0.1)
      expect(h.top_level).to eq(0.8)
    end

    it 'does not flow when expired' do
      h = described_class.new(grain_type: :focus, top_level: 0.0, bottom_level: 1.0)
      h.flow!(0.1)
      expect(h.top_level).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(hourglass.flow!(0.01)).to equal(hourglass)
    end

    it 'transitions to :empty when top_level reaches 0' do
      h = described_class.new(grain_type: :focus, top_level: 0.04, neck_width: 1.0)
      h.flow!(0.1)
      expect(h.state).to eq(:empty)
    end

    it 'keeps top_level non-negative' do
      h = described_class.new(grain_type: :focus, top_level: 0.02, neck_width: 1.0)
      h.flow!(1.0)
      expect(h.top_level).to eq(0.0)
    end

    it 'keeps bottom_level at most 1.0' do
      h = described_class.new(grain_type: :focus, top_level: 0.5, bottom_level: 0.9, neck_width: 1.0)
      h.flow!(1.0)
      expect(h.bottom_level).to be <= 1.0
    end
  end

  describe '#flip!' do
    it 'swaps top and bottom levels' do
      h = described_class.new(grain_type: :focus, top_level: 0.3, bottom_level: 0.7)
      h.flip!
      expect(h.top_level).to be_within(0.001).of(0.7)
      expect(h.bottom_level).to be_within(0.001).of(0.3)
    end

    it 'sets flipped_at' do
      hourglass.flip!
      expect(hourglass.flipped_at).to be_a(Time)
    end

    it 'returns self for chaining' do
      expect(hourglass.flip!).to equal(hourglass)
    end

    it 'changes state after flip' do
      h = described_class.new(grain_type: :focus, top_level: 0.0, bottom_level: 0.8)
      h.flip!
      expect(h.state).not_to eq(:empty)
    end

    it 'becomes fresh after flip' do
      hourglass.flip!
      expect(hourglass.fresh?).to be(true)
    end
  end

  describe '#pause!' do
    it 'sets state to :paused' do
      hourglass.pause!
      expect(hourglass.state).to eq(:paused)
    end

    it 'returns self for chaining' do
      expect(hourglass.pause!).to equal(hourglass)
    end
  end

  describe '#resume!' do
    it 'leaves paused state' do
      hourglass.pause!
      hourglass.resume!
      expect(hourglass.state).not_to eq(:paused)
    end

    it 'returns self for chaining' do
      expect(hourglass.resume!).to equal(hourglass)
    end

    it 're-derives state from levels after resume' do
      h = described_class.new(grain_type: :focus, top_level: 0.5, neck_width: 0.5)
      h.pause!
      h.resume!
      expect(h.state).to eq(:flowing)
    end
  end

  describe '#expired?' do
    it 'returns false when top_level > 0' do
      expect(hourglass.expired?).to be(false)
    end

    it 'returns true when top_level is 0' do
      h = described_class.new(grain_type: :focus, top_level: 0.0, bottom_level: 0.8)
      expect(h.expired?).to be(true)
    end
  end

  describe '#fresh?' do
    it 'returns false when never flipped' do
      expect(hourglass.fresh?).to be(false)
    end

    it 'returns true immediately after flip' do
      hourglass.flip!
      expect(hourglass.fresh?).to be(true)
    end

    it 'returns false when flipped more than 30 seconds ago' do
      hourglass.flip!
      allow(Time).to receive(:now).and_return(Time.now.utc + 31)
      expect(hourglass.fresh?).to be(false)
    end
  end

  describe '#urgency_label' do
    it 'returns a string' do
      expect(hourglass.urgency_label).to be_a(String)
    end

    it 'returns relaxed when top is full (urgency near 0)' do
      h = described_class.new(grain_type: :attention, top_level: 1.0)
      expect(h.urgency_label).to eq('relaxed')
    end

    it 'returns critical when top is nearly empty (urgency near 1)' do
      h = described_class.new(grain_type: :attention, top_level: 0.05, bottom_level: 0.8)
      expect(h.urgency_label).to eq('critical')
    end
  end

  describe '#fullness_label' do
    it 'returns a string' do
      expect(hourglass.fullness_label).to be_a(String)
    end

    it 'returns overflowing when top_level is near 1.0' do
      h = described_class.new(grain_type: :attention, top_level: 0.95)
      expect(h.fullness_label).to eq('overflowing')
    end

    it 'returns empty when top_level is near 0.0' do
      h = described_class.new(grain_type: :attention, top_level: 0.05, bottom_level: 0.8)
      expect(h.fullness_label).to eq('empty')
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = hourglass.to_h
      expect(h.keys).to include(:id, :domain, :grain_type, :top_level, :bottom_level,
                                :neck_width, :state, :expired, :fresh,
                                :urgency_label, :fullness_label, :created_at, :flipped_at)
    end

    it 'expired key reflects expired? state' do
      h = described_class.new(grain_type: :focus, top_level: 0.0, bottom_level: 0.8)
      expect(h.to_h[:expired]).to be(true)
    end

    it 'fresh key reflects fresh? state' do
      hourglass.flip!
      expect(hourglass.to_h[:fresh]).to be(true)
    end
  end
end
