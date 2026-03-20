# Changelog

## [0.1.0] - 2026-03-20

### Added
- Initial release
- `AgentCard` helper: build, parse, and fetch ACP agent cards
- `TaskTranslator` helper: bidirectional ACP-to-Legion task translation
- `Runners::Acp`: `invoke_agent`, `register_external`, `list_agents`, `discover_agents`
- `Actors::Discovery`: scans configured ACP agent URLs every 300 seconds
