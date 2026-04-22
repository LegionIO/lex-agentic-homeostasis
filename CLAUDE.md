# lex-agentic-homeostasis

**Parent**: `../CLAUDE.md`

## What Is This Gem?

Domain consolidation gem for homeostasis, self-regulation, and internal state maintenance. Bundles 20 source extensions into one loadable unit under `Legion::Extensions::Agentic::Homeostasis`.

**Gem**: `lex-agentic-homeostasis`
**Version**: 0.1.8
**Namespace**: `Legion::Extensions::Agentic::Homeostasis`

## Sub-Modules

| Sub-Module | Source Gem | Purpose |
|---|---|---|
| `Homeostasis::Core` | `lex-homeostasis` | Core regulation engine — seven setpoints, allostatic load, negative feedback; runner: `Runners::Homeostasis` |
| `Homeostasis::Homeostasis` | `lex-homeostasis` | Per-variable homeostatic variables — create, perturb, correct; runner: `Runners::CognitiveHomeostasis` |
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

## Runner Methods

### `Core::Runners::Homeostasis`

| Method | Key Args | Returns |
|--------|----------|---------|
| `regulate` | `tick_results: {}` | `{ signals:, regulation_health:, health_label:, allostatic_load:, allostatic_class:, subsystems_regulated:, worst_deviation: }` |
| `modulation_for` | `subsystem:` | `{ subsystem:, signal:, setpoint:, allostatic_load: }` |
| `allostatic_status` | — | allostatic load hash |
| `regulation_overview` | — | full setpoints + signals + health hash |
| `homeostasis_stats` | — | regulation counts, health, deviating subsystems |

### `Homeostasis::Runners::CognitiveHomeostasis`

| Method | Key Args | Returns |
|--------|----------|---------|
| `create_cognitive_variable` | `name:, category:, setpoint:, tolerance:, correction_rate:, initial_value:` | variable hash |
| `perturb_variable` | `variable_id:, amount:` | variable hash |
| `correct_variable` | `variable_id:` | variable hash |
| `correct_all_variables` | — | `{ success:, corrected: }` |
| `drift_all_variables` | `rate:` | `{ success:, drifted: }` |
| `reset_variable` | `variable_id:` | variable hash |
| `out_of_range_report` | — | `{ count:, variables: }` |
| `variables_by_category_report` | `category:` | `{ category:, count:, variables: }` |
| `most_deviated_report` | `limit: 5` | `{ limit:, variables: }` |
| `homeostasis_report` | — | full engine report |
| `update_cognitive_homeostasis` | — | `{ success:, corrected:, stats: }` |
| `cognitive_homeostasis_stats` | — | engine state hash |

## Actors

| Actor | Interval | Target Method |
|-------|----------|---------------|
| `Core::Actor::Regulate` | Every 30s | `regulate` on `Core::Runners::Homeostasis` |
| `Homeostasis::Actor::Correct` | Every 30s | `update_cognitive_homeostasis` on `Homeostasis::Runners::CognitiveHomeostasis` |
| `FatigueModel::Actor::Update` | Every 60s | `update_cognitive_fatigue_model` on `FatigueModel::Runners::CognitiveFatigueModel` |
| `Metabolism::Actor::Cycle` | Every 120s | `run_all_cycles` on `Metabolism::Runners::CognitiveMetabolism` |
| `Tempo::Actor::Adapt` | Every 60s | `run_tempo_adaptation` on `Tempo::Runners::Tempo` |
| `Tide::Actors::TideCycle` | Every 60s | `tide_maintenance` on `Tide::Runners::CognitiveTide` |
| `Neuromodulation::Actors::Drift` | interval | applies neuromodulator drift |
| `NeuralOscillation::Actors::Tick` | interval | advances oscillation bands |
| `Surplus::Actors::Replenish` | interval | replenishes cognitive surplus |
| `Tectonics::Actors::DriftTick` | interval | advances tectonic drift |

## Integration Points

- `Core::Runners::Homeostasis#regulate` accepts `tick_results:` hash from `lex-tick` phase results; extracts observations from `:emotional_evaluation`, `:working_memory_integration`, `:memory_consolidation`, `:prediction_engine`, `:post_tick_reflection`, `:sensory_processing` keys.
- Maps to the `homeostasis_regulation` tick phase.

## Dependencies

**Runtime** (from gemspec):
- `legion-cache` >= 1.3.11
- `legion-crypt` >= 1.4.9
- `legion-data` >= 1.4.17
- `legion-json` >= 1.2.1
- `legion-logging` >= 1.3.2
- `legion-settings` >= 1.3.14
- `legion-transport` >= 1.3.9

## Development

```bash
bundle install
bundle exec rspec        # 2277 examples, 0 failures
bundle exec rubocop      # 0 offenses
```
