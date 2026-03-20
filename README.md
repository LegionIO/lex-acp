# lex-acp

Agent Client Protocol (ACP) adapter for LegionIO. Enables code editors to connect to Legion as a coding agent.

## Usage

```bash
legion acp
```

Configure your editor:
```json
{
  "agent": "legion",
  "command": ["legion", "acp"],
  "transport": "stdio"
}
```

## License

MIT
