# lex-acp

Bidirectional Agent Communication Protocol (ACP) adapter for LegionIO.

Exposes Legion agents via ACP and consumes external ACP agents.

## Features

- Publish an ACP-compatible `/.well-known/agent.json` card via the Legion REST API
- Submit tasks to external ACP agents and register them in the mesh
- Periodic discovery actor scans configured agent URLs every 300 seconds
- Task translation between ACP and Legion formats

## Installation

Add to your `Gemfile`:

```ruby
gem 'lex-acp'
```

## Configuration

```json
{
  "acp": {
    "agents": [
      "https://agent-1.example.com",
      "https://agent-2.example.com"
    ]
  }
}
```
