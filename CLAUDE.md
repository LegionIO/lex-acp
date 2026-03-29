# lex-acp: Agent Client Protocol Adapter for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that implements the Agent Client Protocol (ACP) so code editors (Zed, VS Code, etc.) can connect to Legion as a coding agent via stdio. Uses JSON-RPC 2.0 over stdin/stdout. When `legion-llm` is available, proxies prompts to the configured LLM with streaming. Also exposes Legion-specific slash commands for task engine access. Includes an outbound ACP client runner (`Runners::Acp`) for invoking external ACP agents and registering them in the Legion mesh.

**GitHub**: https://github.com/LegionIO/lex-acp
**License**: MIT
**Version**: 0.1.4

## Architecture

```
Legion::Extensions::Acp
├── Helpers/
│   ├── Protocol        # JSON-RPC 2.0: parse, request, response, error_response,
│   │                   # notification, serialize, read, write, dispatch
│   ├── Capabilities    # Agent info builder: agent_info, agent_capabilities,
│   │                   # custom_commands, llm_available?
│   ├── AgentCard       # Build, parse, and HTTP-fetch /.well-known/agent.json
│   └── TaskTranslator  # acp_to_legion / legion_to_acp payload conversion
├── Transport/
│   └── Stdio           # Read loop over $stdin/$stdout: run, send_response,
│                       # send_notification, log, close
├── Runners/
│   ├── Agent           # Session state machine: handle_initialize, session/new,
│   │                   # session/list, session/cancel, session/set_mode,
│   │                   # session/set_config_option, session/prompt, dispatch
│   │                   # Private: handle_command, execute_run_task,
│   │                   # execute_list_extensions, execute_query_workers,
│   │                   # execute_list_schedules
│   └── Acp             # Outbound ACP client: invoke_agent, register_external,
│                       # list_agents, discover_agents (periodic scan)
└── Actor/              # Note: singular "Actor" (not "Actors") per framework convention
    └── Discovery       # Every 300s: calls Runners::Acp#discover_agents to scan
                        # configured agent URLs and register them in Legion mesh
```

CLI entry point: `legion acp` (default: `legion acp stdio`) — defined in `LegionIO/lib/legion/cli/acp_command.rb`.

## Gem Info

| Field | Value |
|-------|-------|
| Gem name | `lex-acp` |
| Module | `Legion::Extensions::Acp` |
| Version | `0.1.4` |
| Ruby | `>= 3.4` |
| Runtime deps | `json`, `securerandom`, `net/http`, `uri` (stdlib only) |
| Optional | `legion-llm` (prompt handling), `lex-mesh` (agent registry) |
| License | MIT |

## Protocol (Inbound — Runners::Agent)

JSON-RPC 2.0 over newline-delimited stdio. Each message is a single JSON line terminated with `\n`.

**Supported methods:**

| Method | Handler | Notes |
|--------|---------|-------|
| `initialize` | `handle_initialize` | Returns agent info + capabilities; sends `session/update` with commands |
| `session/new` | `handle_session_new` | Returns `{ sessionId: UUID }` |
| `session/list` | `handle_session_list` | Returns `{ sessions: [...] }` |
| `session/cancel` | `handle_session_cancel` | Marks session cancelled (stops streaming mid-prompt) |
| `session/set_mode` | `handle_session_set_mode` | `code` or `chat` |
| `session/set_config_option` | `handle_session_set_config_option` | Stores `model`, `provider`, etc. in session config |
| `session/prompt` | `handle_session_prompt` | LLM proxy (requires legion-llm) or slash command dispatch |

**Custom slash commands** (sent as `session/prompt` with content starting `/`):

| Command | Action |
|---------|--------|
| `/run_task ext.runner.func key:val` | Calls `Legion::Ingress.run` |
| `/list_extensions` | Lists loaded extensions via `Legion::Extensions.loaded_extensions` |
| `/query_workers` | Lists digital workers via `Legion::DigitalWorker::Registry` |
| `/list_schedules` | Lists schedules via Ingress to `Runners::Scheduler` |

## Outbound ACP Client (Runners::Acp)

`invoke_agent(agent_url:, task:, timeout: 30)` — fetches agent card, submits ACP task via HTTP POST to `{agent_url}/tasks`, optionally registers agent in Legion mesh via `lex-mesh`.

`register_external(agent_url:)` — fetches agent card and registers agent capabilities in the mesh registry.

`discover_agents` — iterates `settings[:acp][:agents]` URLs and calls `register_external` for each. Called by `Actor::Discovery` every 300 seconds.

`list_agents` — returns all agents known to the mesh registry.

## AgentCard Helper

`Helpers::AgentCard.build(name:, url:, capabilities:, description:)` — constructs a standard ACP 2.0 agent card hash.

`Helpers::AgentCard.fetch(base_url)` — fetches `/.well-known/agent.json` via HTTP and returns parsed card or `nil`.

`Helpers::AgentCard.parse(json)` — parses JSON string or hash into symbolized card; returns `nil` if `name` or `url` is absent.

## TaskTranslator Helper

`Helpers::TaskTranslator.acp_to_legion(acp_task)` — converts ACP task input to Legion task hash (`payload:`, `source: 'acp'`, `runner_class:`, `function:`).

`Helpers::TaskTranslator.legion_to_acp(legion_result)` — converts Legion result hash to ACP task response with `status: 'completed'/'failed'`, `output:`, `created_at:`, `completed_at:`.

## Session State

Each session is a hash stored in `@sessions[uuid]`:

```ruby
{
  id:         uuid,
  created_at: ISO8601,
  mode:       'code',    # or 'chat'
  config:     {},        # model:, provider: set via session/set_config_option
  cancelled:  false      # set true by session/cancel; stops streaming mid-chunk
}
```

## LLM Proxy Behaviour

When `legion-llm` is loaded and `Legion::LLM.started?` is true:
- Streams chunks via `session/update` notifications (`contentBlock: { type: 'text', text: chunk }`)
- Passes `caller: { extension: 'lex-acp', operation: 'agent', session_id: uuid }` to `Legion::LLM.chat` for attribution
- Returns `response.content` as the authoritative final content
- Stop reasons: `end_turn`, `cancelled` (if session cancelled mid-stream), `error`

When `legion-llm` is unavailable: returns `{ error: 'LLM not available...' }`.

## Known Behaviour Notes

- `full_content` accumulator uses `+''` (mutable string) — required under `# frozen_string_literal: true`
- Actor module is `module Actor` (singular), not `module Actors` — this matches framework convention for `Once`/`Every` actor discovery
- Outbound ACP client (`Runners::Acp`) uses stdlib `net/http` only — no gem dependencies for HTTP calls
- `data_required? false` — no database dependency

## Testing

```bash
bundle install
bundle exec rspec
bundle exec rubocop   # 0 offenses
```

---

**Maintained By**: Matthew Iverson (@Esity)
