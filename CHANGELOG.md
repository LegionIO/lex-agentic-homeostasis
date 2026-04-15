# Changelog

## [0.1.7] - 2026-04-15
### Changed
- Set `mcp_tools?`, `mcp_tools_deferred?`, and `transport_required?` to `false` — internal cognitive pipeline extension

## [0.1.6] - 2026-04-06

### Fixed
- fix extract_attention to read correct filter_signals output keys for attention breadth calculation

## [0.1.5] - 2026-03-30

### Changed
- update to rubocop-legion 0.1.7, resolve all offenses

## [0.1.4] - 2026-03-26

### Changed
- fix remote_invocable? to use class method for local dispatch

## [0.1.3] - 2026-03-22

### Changed
- Add 7 runtime dependencies (legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport) to gemspec
- Update spec_helper to require and include real sub-gem helpers in Helpers::Lex and actor stubs (TIER 1 migration)

## [0.1.2] - 2026-03-18

### Changed
- Enforce VARIABLE_CATEGORIES validation in HomeostasisEngine#create_variable (returns nil for invalid category)
- Add :general to VARIABLE_CATEGORIES to support default category value
- Enforce RHYTHM_TYPES validation in RhythmEngine#add_rhythm (returns nil for invalid rhythm_type)
- Enforce COGNITIVE_DIMENSIONS validation in RhythmEngine#add_rhythm (returns nil for invalid dimension)

## [0.1.1] - 2026-03-18

### Changed
- Enforce COCOON_TYPES validation in Incubator#create_cocoon (returns nil for invalid type)

## [0.1.0] - 2026-03-18

### Added
- Initial release as domain consolidation gem
- Consolidated source extensions into unified domain gem under `Legion::Extensions::Agentic::<Domain>`
- All sub-modules loaded from single entry point
- Full spec suite with zero failures
- RuboCop compliance across all files
