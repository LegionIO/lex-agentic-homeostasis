# lex-agentic-homeostasis

Domain consolidation gem for homeostasis, self-regulation, and internal state maintenance. Bundles 20 source extensions into one loadable unit under `Legion::Extensions::Agentic::Homeostasis`.

## Overview

**Gem**: `lex-agentic-homeostasis`
**Version**: 0.1.7
**Namespace**: `Legion::Extensions::Agentic::Homeostasis`

## Sub-Modules

| Sub-Module | Source Gem | Purpose |
|---|---|---|
| `Homeostasis::Homeostasis` | `lex-homeostasis` | Seven-setpoint negative feedback regulation, allostatic load |
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
| `Homeostasis::Core` | `lex-homeostasis` | Core homeostasis regulation engine — seven setpoints, allostatic load, negative feedback regulator |
| `Homeostasis::Neuromodulation` | `lex-neuromodulation` | Dopamine/serotonin/norepinephrine/acetylcholine analogs |
| `Homeostasis::NeuralOscillation` | `lex-neural-oscillation` | Gamma/beta/alpha/theta/delta bands, cross-frequency coupling |
| `Homeostasis::Temporal` | `lex-temporal` | Temporal reasoning — event ordering, duration estimation |
| `Homeostasis::TemporalDiscounting` | `lex-temporal-discounting` | Hyperbolic discounting of future rewards |
| `Homeostasis::Surplus` | `lex-cognitive-surplus` | Excess cognitive capacity allocation |
| `Homeostasis::Tectonics` | `lex-cognitive-tectonics` | Deep structural cognitive shifts |
| `Homeostasis::Furnace` | `lex-cognitive-furnace` | High-intensity cognitive processing — ore to alloy smelting metaphor |

## Actors

- `Homeostasis::NeuralOscillation::Actors::Tick` — interval actor, advances oscillation bands
- `Homeostasis::Neuromodulation::Actors::Drift` — interval actor, applies neuromodulator drift
- `Homeostasis::Surplus::Actors::Replenish` — interval actor, replenishes cognitive surplus
- `Homeostasis::Tectonics::Actors::DriftTick` — interval actor, advances tectonic drift
- `Homeostasis::Tempo::Actors::Adapt` — interval actor, adapts processing tempo
- `Homeostasis::Tide::Actors::TideCycle` — runs every 60s, executes `tide_maintenance`

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
