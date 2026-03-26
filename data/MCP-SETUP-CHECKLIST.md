# GMA MCP Setup Checklist

## Prerequisites
- [ ] MCP client configured with three SSE servers (see `data/google-ads-mcp.config.template.json`)
- [ ] GMA Editor Bearer token obtained (for write operations)

## First live test
1. Call `list_accessible_customers` on GMA Reader MCP
2. Call `list_knowledge_base_stats` on GMA Knowledge MCP
3. Choose target customer ID
4. Run a simple campaign query via `search` tool
5. Run a search terms query

## Success criteria
- Account list returns from GMA Reader
- Both KB collections (gma_training, ppc_copilot) show active
- GAQL queries return live data with structured parameters
- `/google-ads daily` and `/google-ads search-terms` operate in connected mode
