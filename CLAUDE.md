# lex-agentic-homeostasis

**Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## What Is This Gem?

Domain consolidation gem for homeostasis, self-regulation, and internal state maintenance. Bundles 20 source extensions into one loadable unit under `Legion::Extensions::Agentic::Homeostasis`.

**Gem**: `lex-agentic-homeostasis`
**Version**: 0.1.0
**Namespace**: `Legion::Extensions::Agentic::Homeostasis`

## Sub-Modules

| Sub-Module | Source Gem | Purpose |
|---|---|---|
| `Homeostasis::Homeostasis` | `lex-homeostasis` | Seven-setpoint negative feedback regulation, allostatic load |
| `Homeostasis::FatigueModel` | `lex-cognitive-fatigue-model` | Cognitive resource depletion curves across session time |
| `Homeostasis::Metabolism` | `lex-cognitive-metabolism` | Energy budget allocation and cognitive metabolic rate |
| `Homeostasis::Rhythm` | `lex-cognitive-tide` | Circadian-like cognitive rhythm — sinusoidal oscillators, peak/low tide |
| `Homeostasis::Tempo` | `lex-cognitive-tempo` | Processing speed modulation |
| `Homeostasis::Tide` | `lex-cognitive-tide` | Tidal pool maintenance — periodic tide cycle |
| `Homeostasis::Weathering` | `lex-cognitive-weathering` | Gradual wear on cognitive structures |
| `Homeostasis::Weather` | `lex-cognitive-weather` | Unpredictable environmental cognitive conditions |
| `Homeostasis::Pendulum` | `lex-cognitive-pendulum` | Oscillation between cognitive states |
| `Homeostasis::Cocoon` | `lex-cognitive-cocoon` | Protective withdrawal and recovery state |
| `Homeostasis::FossilFuel` | `lex-cognitive-fossil-fuel` | Stored energy from past experience |
| `Homeostasis::Hourglass` | `lex-cognitive-hourglass` | Time-based resource depletion tracking |
| `Homeostasis::Core` | `lex-privatecore` | PII stripping, probe detection, cryptographic erasure with audit log |
| `Homeostasis::Neuromodulation` | `lex-neuromodulation` | Dopamine/serotonin/norepinephrine/acetylcholine analogs |
| `Homeostasis::NeuralOscillation` | `lex-neural-oscillation` | Gamma/beta/alpha/theta/delta bands, cross-frequency coupling |
| `Homeostasis::Temporal` | `lex-temporal` | Temporal reasoning — event ordering, duration estimation |
| `Homeostasis::TemporalDiscounting` | `lex-temporal-discounting` | Hyperbolic discounting of future rewards |
| `Homeostasis::Surplus` | `lex-cognitive-surplus` | Excess cognitive capacity allocation |
| `Homeostasis::Tectonics` | `lex-cognitive-tectonics` | Deep structural cognitive shifts |
| `Homeostasis::Furnace` | `lex-cognitive-furnace` | High-intensity cognitive processing — ore to alloy smelting metaphor |

## Actors

- `Homeostasis::Tide::Actors::TideCycle` — runs every 60s, executes `tide_maintenance`
- `Homeostasis::Core::Actors::AuditPrune` — runs every 3600s, prunes audit log

## Development

```bash
bundle install
bundle exec rspec        # 2269 examples, 0 failures
bundle exec rubocop      # 0 offenses
```
