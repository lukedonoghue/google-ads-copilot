---
name: google-ads-pmax
description: >
  Analyze Performance Max through the lens of intent contamination, cannibalization,
  weak control surfaces, and what can still be learned despite PMax opacity.
  Pulls live data via MCP or works with manual exports.
---

# Google Ads PMax

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/intent-map.md`
- `google-ads/references/query-patterns.md`
- `google-ads/references/structure-playbook.md`
- `google-ads/references/benchmarks.md`
- `google-ads/references/deliverable-templates.md`

Read workspace if available:
- `workspace/ads/account.md`
- `workspace/ads/goals.md`
- `workspace/ads/intent-map.md`
- `workspace/ads/findings.md`
- `workspace/ads/change-log.md`
- `workspace/ads/learnings.md`

### MCP Tools
Load before first use:
- GMA Reader: `ToolSearch("select:mcp__gma-reader__search,mcp__gma-reader__list_accessible_customers")`
- GMA Knowledge: `ToolSearch("+gma knowledge search")`

---

## Data Acquisition

### Connected Mode (MCP available)

Pull via the `search` tool on GMA Reader MCP:

**Primary: PMax campaign performance:**
Use the structured `search` tool:
- **resource:** `campaign`
- **fields:** `campaign.name, campaign.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.conversions_value, metrics.cost_per_conversion`
- **conditions:** `campaign.advertising_channel_type = 'PERFORMANCE_MAX' AND campaign.status = 'ENABLED' AND segments.date BETWEEN '{today-30}' AND '{today}'`

**Primary: Asset group performance:**
Use the structured `search` tool:
- **resource:** `asset_group`
- **fields:** `campaign.name, asset_group.name, asset_group.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions`
- **conditions:** `campaign.advertising_channel_type = 'PERFORMANCE_MAX' AND segments.date BETWEEN '{today-30}' AND '{today}'`

**Supplementary: Compare with Search campaign performance (cannibalization check):**
Use the structured `search` tool:
- **resource:** `campaign`
- **fields:** `campaign.name, campaign.advertising_channel_type, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.cost_per_conversion`
- **conditions:** `campaign.status = 'ENABLED' AND segments.date BETWEEN '{today-30}' AND '{today}'`
- **orderings:** `metrics.cost_micros DESC`

See `data/gaql-recipes.md` for additional queries.

### Export Mode (no MCP)

Ask the user for:
- PMax campaign metrics
- Asset group list with performance
- Search campaign performance (for comparison)
- Any listing group or audience signal notes

---

## Core Questions
- Is PMax cannibalizing branded or clean high-intent traffic?
- Is it helping discover net-new signal, or just absorbing existing demand?
- What can we infer about intent quality despite limited visibility?
- What should be protected outside PMax?
- What should be fixed in feeds, exclusions, or surrounding structure?

## Process
1. **Announce mode** (connected/export).
2. **Query knowledge base before analysis:**
   - `search_both_advisors("Performance Max optimization brand exclusions configuration")`
   - For cannibalization: `search_both_advisors("PMax cannibalizing search branded traffic brand exclusions")`
3. Pull PMax and Search campaign data.
4. Compare PMax vs. Search on shared conversion actions.
5. Look for branded cannibalization signals.
6. Assess asset group quality.
7. Attempt PMax query visibility recovery using Steps 5/5b from the shared retrieval ladder (`data/search-term-retrieval.md`).
8. Separate **direct evidence** from **inference**. Query rows from PMax are useful, but they do not automatically carry the same term-level cost / CPA detail as classic Search reports.
9. Identify what should be protected in dedicated Search campaigns.

## Draft Output
PMax analysis **typically does not produce its own draft type** — its findings feed into:
- **Structure drafts** (if PMax is cannibalizing, recommend brand exclusions or campaign restructure)
- **Negative drafts** (if account-level negatives can help contain PMax)
- **Budget drafts** (if PMax is absorbing budget that should go to proven Search campaigns)

When PMax-specific actions are needed, use the structure draft template and note the PMax context.

### Always update workspace memory:
- `workspace/ads/findings.md` — PMax observations (inference vs. direct evidence)
- `workspace/ads/learnings.md` — what we learned about PMax behavior in this account

## Output Format
Use operator summary, then add:
- Cannibalization risks (with evidence level)
- Useful signal PMax may still be surfacing
- What should be protected in Search or other buckets
- What is direct evidence vs inference

## Rules
- Treat PMax as useful but not self-explanatory.
- Look for contamination before celebrating efficiency.
- Protect clean branded and high-intent buckets when needed.
- Be explicit about what is inference versus direct evidence.
- If visibility is weak, say that clearly instead of pretending certainty.
