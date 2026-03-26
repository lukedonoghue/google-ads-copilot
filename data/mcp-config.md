# MCP Server Configuration — Google Ads Copilot (GMA Edition)

## Overview

This fork of Google Ads Copilot runs on **Grow My Ads' deployed MCP infrastructure** on Fly.io. No local credentials, no pipx, no OAuth setup. Three remote MCP servers handle reads, writes, and methodology.

## MCP Servers

### 1. GMA Reader — Account Data (Read-Only)

**URL:** `https://growmyads-google-ads-mcp.fly.dev/sse`
**MCC ID:** `5294823448` (pre-configured on server)

| Tool | Purpose |
|------|---------|
| `search` | Query Google Ads data using structured parameters (resource, fields, conditions, orderings, limit) |
| `list_accessible_customers` | List all customer IDs accessible under the MCC |
| `get_resource_metadata` | Look up field definitions for any Google Ads resource |

**Important:** The `search` tool uses structured parameters, NOT raw GAQL strings. Date literals like `DURING LAST_30_DAYS` are **forbidden** — use explicit `BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'` ranges.

### 2. GMA Editor — Account Changes (Write)

**URL:** `https://growmyads-google-ads-mcp-write.fly.dev/sse`
**Auth:** Bearer token required

| Tool | Purpose |
|------|---------|
| `add_campaign_negative_keyword` | Add a negative keyword to a campaign |
| `add_campaign_negative_keywords_bulk` | Add multiple negatives to a campaign in one call |
| `remove_campaign_negative_keyword` | Remove a campaign negative keyword |
| `update_keyword` | Update keyword status or bids |
| `remove_keyword` | Remove a keyword |
| `add_keyword` | Add a keyword to an ad group |
| `update_ad_group_status` | Pause/enable an ad group |
| `update_ad_group_bids` | Update ad group bids |
| `update_ad_status` | Pause/enable an ad |
| `create_responsive_search_ad` | Create a new RSA |
| `update_campaign_status` | Pause/enable a campaign |
| `update_campaign_budget` | Change a campaign's daily budget |
| `update_campaign_bidding` | Change bidding strategy |

### 3. GMA Knowledge — Methodology (RAG)

**URL:** `https://growmyads-knowledge-mcp.fly.dev/sse`

| Tool | Purpose |
|------|---------|
| `search_gma_training` | Search founder's methodology (YouTube + Loom training). **Primary authority.** |
| `search_ppc_copilot` | Search PPC Copilot framework (228 structured docs). Secondary opinion. |
| `search_both_advisors` | Search both KBs and return side-by-side results. Best for optimization decisions. |
| `list_knowledge_base_stats` | Check collection status and point counts |

---

## Setup

### For Claude Code / Claude Desktop

Add all three servers to your MCP configuration. See `data/google-ads-mcp.config.template.json` for the template.

### For Cloud Teams

The servers are already configured as connectors:
- **Google Ads MCP** (reader)
- **Google Ads Editor** (writer)
- **GMA Knowledge Base** (methodology)

### Verify

Test connectivity:
1. Call `list_accessible_customers` on the reader → should return customer IDs
2. Call `list_knowledge_base_stats` on knowledge → should show both collections active
3. Call `search` with a simple campaign query on any account

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| 401 Unauthorized | Check Bearer token is correct and included in headers |
| SSE connection timeout | Fly.io machines may be cold-starting. Retry after 5 seconds. |
| Empty search results | Check customer_id format (no dashes). Check date range is valid. |
| "Date literals not supported" | Replace `DURING LAST_30_DAYS` with explicit `BETWEEN` dates |
| Knowledge KB unavailable | Check `list_knowledge_base_stats`. Collections may be reindexing. |
| Write tool rejected | Verify Bearer token for the editor server specifically |

## Security Notes

- All credentials are managed as Fly.io secrets — never in code
- The reader server is read-only by design
- The editor server requires Bearer token auth for every request
- No local credential files needed — the team can use this immediately
