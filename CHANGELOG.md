# Changelog

## [Unreleased]

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
