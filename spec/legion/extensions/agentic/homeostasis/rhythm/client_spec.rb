# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Homeostasis::Rhythm::Client do
  subject(:client) { described_class.new }

  it 'full lifecycle: add rhythms, check state, profile, best time' do
    r1 = client.add_cognitive_rhythm(name: 'focus ultradian', rhythm_type: :ultradian, dimension: :focus)
    expect(r1[:success]).to be true

    r2 = client.add_cognitive_rhythm(
      name: 'creativity boost', rhythm_type: :ultradian, dimension: :creativity, amplitude: 0.7
    )
    expect(r2[:success]).to be true

    state = client.current_rhythm_state
    expect(state[:success]).to be true
    expect(state[:state][:focus]).to be_a(Float)

    profile = client.cognitive_rhythm_profile
    expect(profile[:success]).to be true
    expect(profile[:profile][:focus]).to include(:value, :optimal)

    best = client.best_time_for_task(dimension: :focus)
    expect(best[:success]).to be true
    expect(best[:best_time]).to be_a(String)
  end

  it 'accepts injected engine' do
    engine = Legion::Extensions::Agentic::Homeostasis::Rhythm::Helpers::RhythmEngine.new
    c = described_class.new(engine: engine)
    c.add_cognitive_rhythm(name: 'test', rhythm_type: :ultradian, dimension: :focus)
    expect(engine.to_h[:rhythm_count]).to eq(1)
  end

  it 'add and remove rhythm lifecycle' do
    added = client.add_cognitive_rhythm(name: 'temp', rhythm_type: :ultradian, dimension: :alertness)
    expect(added[:success]).to be true

    removed = client.remove_cognitive_rhythm(rhythm_id: added[:rhythm_id])
    expect(removed[:success]).to be true

    stats = client.cognitive_rhythm_stats
    expect(stats[:rhythm_count]).to eq(0)
  end

  it 'peak and trough dimension queries' do
    client.add_cognitive_rhythm(name: 'r', rhythm_type: :ultradian, dimension: :analytical)

    peaks = client.peak_cognitive_dimensions
    expect(peaks[:success]).to be true

    troughs = client.trough_cognitive_dimensions
    expect(troughs[:success]).to be true
  end
end
