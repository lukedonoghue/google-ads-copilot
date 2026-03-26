# Next Steps — GMA MCP Setup

## What is ready now
- Three remote MCP servers deployed on Fly.io (reader, editor, knowledge)
- No local credentials needed — auth is handled server-side
- MCP config template at `data/google-ads-mcp.config.template.json`

## Setup
1. Add the three MCP servers to your client config using the template
2. For write operations, obtain the GMA Editor Bearer token
3. Test with `list_accessible_customers` on the reader
4. Test with `list_knowledge_base_stats` on the knowledge server
5. Run `/google-ads connect setup` to discover accounts

## MCP Servers
| Server | URL | Auth |
|--------|-----|------|
| GMA Reader | `growmyads-google-ads-mcp.fly.dev/sse` | None required |
| GMA Editor | `growmyads-google-ads-mcp-write.fly.dev/sse` | Bearer token |
| GMA Knowledge | `growmyads-knowledge-mcp.fly.dev/sse` | None required |
