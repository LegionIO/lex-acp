# Changelog

## [0.1.3] - 2026-03-23

### Changed
- Add `caller:` identity to `Legion::LLM.chat` call in `Runners::Agent#handle_session_prompt` with `extension: 'lex-acp'`, `operation: 'agent'`, and `session_id`

## [0.1.2] - 2026-03-22

### Changed
- Migrated to Tier 1 sub-gem helpers: added runtime deps for legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport
- Replaced inline stubs in spec_helper with real sub-gem helper requires and Helpers::Lex composite module

## [0.1.1] - 2026-03-21

### Changed
- Merged extension scaffold and ACP client implementations
- Added ACP discovery actor for scanning configured agent URLs
- Spec suite at 73 examples (0 failures)

## [0.1.0] - 2026-03-20

### Added
- Initial release
- `AgentCard` helper: build, parse, and fetch ACP agent cards
- `TaskTranslator` helper: bidirectional ACP-to-Legion task translation
- `Runners::Acp`: `invoke_agent`, `register_external`, `list_agents`, `discover_agents`
- `Actors::Discovery`: scans configured ACP agent URLs every 300 seconds
- JSON-RPC 2.0 protocol layer (Helpers::Protocol)
- Agent capabilities builder (Helpers::Capabilities)
- Stdio transport (Transport::Stdio)
- Agent-side ACP handlers (Runners::Agent)
- CLI entry point (`legion acp`)
