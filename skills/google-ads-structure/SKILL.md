---
name: google-ads-structure
description: >
  Recommend Google Ads campaign and ad group structure based on intent separation,
  routing problems, brand/non-brand boundaries, competitor isolation, and landing-page fit.
  Pulls live data via MCP or works with manual exports. Produces structure drafts.
---

# Google Ads Structure

### MCP Tools
Load before first use:
- GMA Reader: `ToolSearch("select:mcp__gma-reader__search,mcp__gma-reader__list_accessible_customers")`
- GMA Knowledge: `ToolSearch("+gma knowledge search")`

### Knowledge Base Queries
- Before analysis: `search_both_advisors("campaign structure intent separation ad group design")`
- For split/merge: `search_both_advisors("when to split campaigns ad groups volume thresholds")`

Before analyzing the data, query the GMA Knowledge MCP to understand what the methodology recommends for campaign structure.

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/intent-map.md`
- `google-ads/references/query-patterns.md`
- `google-ads/references/structure-playbook.md`
- `google-ads/references/deliverable-templates.md`

Read workspace if available:
- `workspace/ads/account.md`
- `workspace/ads/goals.md`
- `workspace/ads/intent-map.md`
- `workspace/ads/queries.md`
- `workspace/ads/winners.md`
- `workspace/ads/change-log.md`
- `workspace/ads/learnings.md`

---

## Data Acquisition

### Connected Mode (MCP available)

Pull via the `search` tool on the GMA Reader MCP. Use the structured `search(resource, fields, conditions, orderings, limit)` format.

**Primary: Ad group structure with performance:**
```
Resource: ad_group
Fields: campaign.name, campaign.advertising_channel_type, ad_group.name, ad_group.status, ad_group.type, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.cost_per_conversion
Conditions: campaign.status = 'ENABLED', ad_group.status = 'ENABLED', segments.date BETWEEN '{today-30}' AND '{today}'
Orderings: campaign.name, ad_group.name
```

**Primary: Keywords per ad group (intent mixing check):**
```
Resource: keyword_view
Fields: campaign.name, ad_group.name, ad_group_criterion.keyword.text, ad_group_criterion.keyword.match_type, ad_group_criterion.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions
Conditions: campaign.status = 'ENABLED', ad_group.status = 'ENABLED', segments.date BETWEEN '{today-30}' AND '{today}'
Orderings: campaign.name, ad_group.name
```

**Supplementary: Search terms (to verify routing):**
```
Resource: search_term_view
Fields: search_term_view.search_term, campaign.name, ad_group.name, metrics.cost_micros, metrics.conversions
Conditions: segments.date BETWEEN '{today-30}' AND '{today}'
Orderings: metrics.cost_micros DESC
Limit: 300
```

See `data/gaql-recipes.md` for additional queries.

### Export Mode (no MCP)

Ask the user for:
- Campaign list with types, budgets, bid strategies
- Ad group list with campaign parent
- Keywords per ad group (at least the main ones)
- Search terms report helps but is not strictly required

---

## Process
1. **Announce mode** (connected/export).
2. Before analysis, query the GMA Knowledge MCP: `search_both_advisors("campaign structure intent separation ad group design")` to understand what the methodology recommends.
3. Identify where unlike intent is currently mixed.
4. Determine whether the problem is better solved by split, merge, or routing.
5. Before split/merge decisions, query: `search_both_advisors("when to split campaigns ad groups volume thresholds")`.
6. Evaluate whether current campaign and ad group boundaries reflect real commercial meaning.
7. Recommend actions: keep / clean up / split / merge / route / rebuild.
8. Update workspace memory.

## Core Questions
- What traffic types are wrongly sharing one optimization bucket?
- Where is generic structure hiding high-intent signal?
- Where are negatives doing patchwork for a deeper structure problem?
- What structure would make bidding, copy, LPs, and reporting cleaner?

## Draft Output

### Structure Draft
**Trigger:** Analysis identifies intent mixing with measurable performance impact.

Create using `drafts/templates/structure-draft.md`:
- Write to `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-structure.md`
- Specify: current state, proposed state, keywords to move, budget impact, risk, reversibility
- Note dependencies on other drafts (e.g., "Add negatives first to prevent traffic bleed during restructure")
- Update `workspace/ads/drafts/_index.md`

### Always update workspace memory:
- `workspace/ads/findings.md` — structural observations
- `workspace/ads/change-log.md` — if recommending changes
- `workspace/ads/intent-map.md` — if routing analysis reveals new intent classes

## Output Shape
1. **Account Status block** — account name, CID, status, date range used, tracking confidence, mode
2. Current structure map (campaigns, ad groups, keyword/intent distribution)
3. Intent mixing analysis — include "What the methodology says" citation per finding
4. Split/merge/route recommendations — include "What the methodology says" citation
5. Draft created (path and summary)
6. Memory updates

## Rules
- Do not split just because the account feels messy.
- Do not over-segment thin volume.
- Recommend routing when negatives can solve the problem more cleanly than new structure.
- Distinguish between cleanup and full rebuild.
