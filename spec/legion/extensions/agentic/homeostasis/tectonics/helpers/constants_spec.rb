# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::Constants do
  let(:klass) do
    Class.new { include Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::Constants }
  end
  let(:instance) { klass.new }

  describe 'MAX_PLATES' do
    it 'is 50' do
      expect(described_module::MAX_PLATES).to eq(50)
    end
  end

  describe 'MAX_QUAKES' do
    it 'is 200' do
      expect(described_module::MAX_QUAKES).to eq(200)
    end
  end

  describe 'BOUNDARY_TYPES' do
    it 'contains convergent, divergent, transform' do
      expect(described_module::BOUNDARY_TYPES).to eq(%i[convergent divergent transform])
    end

    it 'is frozen' do
      expect(described_module::BOUNDARY_TYPES).to be_frozen
    end
  end

  describe 'COLLISION_THRESHOLD' do
    it 'is 0.2' do
      expect(described_module::COLLISION_THRESHOLD).to eq(0.2)
    end
  end

  describe 'SUBDUCTION_RATIO' do
    it 'is 0.7' do
      expect(described_module::SUBDUCTION_RATIO).to eq(0.7)
    end
  end

  describe 'AFTERSHOCK_DECAY' do
    it 'is 0.3' do
      expect(described_module::AFTERSHOCK_DECAY).to eq(0.3)
    end
  end

  describe 'PLATE_STATES' do
    it 'contains active, subducted, dormant' do
      expect(described_module::PLATE_STATES).to eq(%i[active subducted dormant])
    end

    it 'is frozen' do
      expect(described_module::PLATE_STATES).to be_frozen
    end
  end

  describe 'MAGNITUDE_LABELS' do
    it 'is a hash' do
      expect(described_module::MAGNITUDE_LABELS).to be_a(Hash)
    end

    it 'covers micro through great ranges' do
      labels = described_module::MAGNITUDE_LABELS.values
      expect(labels).to include(:micro, :minor, :light, :moderate, :strong, :great)
    end
  end

  describe '#label_for' do
    it 'returns :micro for magnitude 0.5' do
      expect(instance.label_for(0.5)).to eq(:micro)
    end

    it 'returns :minor for magnitude 1.5' do
      expect(instance.label_for(1.5)).to eq(:minor)
    end

    it 'returns :light for magnitude 2.5' do
      expect(instance.label_for(2.5)).to eq(:light)
    end

    it 'returns :moderate for magnitude 3.5' do
      expect(instance.label_for(3.5)).to eq(:moderate)
    end

    it 'returns :strong for magnitude 4.5' do
      expect(instance.label_for(4.5)).to eq(:strong)
    end

    it 'returns :great for magnitude 6.0' do
      expect(instance.label_for(6.0)).to eq(:great)
    end
  end

  def described_module
    Legion::Extensions::Agentic::Homeostasis::Tectonics::Helpers::Constants
  end
end
