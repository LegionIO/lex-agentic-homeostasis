# lex-agentic-homeostasis

Domain consolidation gem for homeostasis, self-regulation, and internal state maintenance. Bundles 20 source extensions into one loadable unit under `Legion::Extensions::Agentic::Homeostasis`.

## Overview

**Gem**: `lex-agentic-homeostasis`
**Version**: 0.1.8
**Namespace**: `Legion::Extensions::Agentic::Homeostasis`

## Sub-Modules

| Sub-Module | Source Gem | Purpose |
|---|---|---|
| `Homeostasis::Core` | `lex-homeostasis` | Core regulation engine — seven setpoints, allostatic load, negative feedback |
| `Homeostasis::Homeostasis` | `lex-homeostasis` | Per-variable homeostatic tracking — create, perturb, correct cognitive variables |
| `Homeostasis::FatigueModel` | `lex-cognitive-fatigue-model` | Cognitive resource depletion curves across session time |
| `Homeostasis::Metabolism` | `lex-cognitive-metabolism` | Energy budget allocation and cognitive metabolic rate |
| `Homeostasis::Rhythm` | `lex-cognitive-rhythm` | Circadian-like cognitive rhythm — sinusoidal oscillators, peak/low tide |
| `Homeostasis::Tempo` | `lex-cognitive-tempo` | Processing speed modulation |
| `Homeostasis::Tide` | `lex-cognitive-tide` | Tidal pool maintenance — periodic tide cycle |
| `Homeostasis::Weathering` | `lex-cognitive-weathering` | Gradual wear on cognitive structures |
| `Homeostasis::Weather` | `lex-cognitive-weather` | Unpredictable environmental cognitive conditions |
| `Homeostasis::Pendulum` | `lex-cognitive-pendulum` | Oscillation between cognitive states |
| `Homeostasis::Cocoon` | `lex-cognitive-cocoon` | Protective withdrawal and recovery state |
| `Homeostasis::FossilFuel` | `lex-cognitive-fossil-fuel` | Stored energy from past experience |
| `Homeostasis::Hourglass` | `lex-cognitive-hourglass` | Time-based resource depletion tracking |
| `Homeostasis::Neuromodulation` | `lex-neuromodulation` | Dopamine/serotonin/norepinephrine/acetylcholine analogs |
| `Homeostasis::NeuralOscillation` | `lex-neural-oscillation` | Gamma/beta/alpha/theta/delta bands, cross-frequency coupling |
| `Homeostasis::Temporal` | `lex-temporal` | Temporal reasoning — event ordering, duration estimation |
| `Homeostasis::TemporalDiscounting` | `lex-temporal-discounting` | Hyperbolic discounting of future rewards |
| `Homeostasis::Surplus` | `lex-cognitive-surplus` | Excess cognitive capacity allocation |
| `Homeostasis::Tectonics` | `lex-cognitive-tectonics` | Deep structural cognitive shifts |
| `Homeostasis::Furnace` | `lex-cognitive-furnace` | High-intensity cognitive processing — ore to alloy smelting metaphor |

## Actors

| Actor | Interval | What It Does |
|-------|----------|--------------|
| `Core::Actor::Regulate` | Every 30s | Runs negative-feedback regulation across all seven setpoints |
| `Homeostasis::Actor::Correct` | Every 30s | Corrects all out-of-tolerance cognitive variables |
| `FatigueModel::Actor::Update` | Every 60s | Advances fatigue depletion curve |
| `Metabolism::Actor::Cycle` | Every 120s | Runs all metabolic cycles |
| `Tempo::Actor::Adapt` | Every 60s | Adapts processing tempo to current load |
| `Tide::Actors::TideCycle` | Every 60s | Executes tidal maintenance cycle |
| `Neuromodulation::Actors::Drift` | interval | Applies neuromodulator drift |
| `NeuralOscillation::Actors::Tick` | interval | Advances oscillation bands |
| `Surplus::Actors::Replenish` | interval | Replenishes cognitive surplus |
| `Tectonics::Actors::DriftTick` | interval | Advances tectonic drift |

## Installation

```ruby
gem 'lex-agentic-homeostasis'
```

## Development

```bash
bundle install
bundle exec rspec        # 2277 examples, 0 failures
bundle exec rubocop      # 0 offenses
```

## License

MIT
