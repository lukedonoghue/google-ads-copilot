---
name: google-ads-budget
description: >
  Review Google Ads budget allocation and scaling decisions based on signal quality,
  intent clarity, tracking confidence, and structural health. Pulls live data via MCP
  or works with manual exports. Produces budget reallocation drafts.
---

# Google Ads Budget

### MCP Tools
Load before first use:
- GMA Reader: `ToolSearch("select:mcp__gma-reader__search,mcp__gma-reader__list_accessible_customers")`
- GMA Knowledge: `ToolSearch("+gma knowledge search")`

### Knowledge Base Queries
- Before analysis: `search_both_advisors("budget allocation scaling bids minimum viable budget")`
- For tracking gate: `search_gma_training("tracking confidence budget decisions")`

Before analyzing the data, query the GMA Knowledge MCP to understand what the methodology recommends for budget allocation.

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/intent-map.md`
- `google-ads/references/tracking-playbook.md`
- `google-ads/references/structure-playbook.md`
- `google-ads/references/budget-playbook.md`
- `google-ads/references/deliverable-templates.md`

Read workspace if available:
- `workspace/ads/account.md`
- `workspace/ads/goals.md`
- `workspace/ads/intent-map.md`
- `workspace/ads/winners.md`
- `workspace/ads/findings.md`
- `workspace/ads/change-log.md`
- `workspace/ads/learnings.md`
- `workspace/ads/drafts/_index.md` — check if tracking fixes are pending (gates scaling)

---

## Data Acquisition

### Connected Mode (MCP available)

Pull via the `search` tool on the GMA Reader MCP. Use the structured `search(resource, fields, conditions, orderings, limit)` format.

**Primary: Campaign budgets and spend:**
```
Resource: campaign
Fields: campaign.name, campaign.status, campaign_budget.amount_micros, campaign_budget.delivery_method, campaign.bidding_strategy_type, metrics.cost_micros, metrics.conversions, metrics.cost_per_conversion, metrics.impressions, metrics.search_impression_share
Conditions: campaign.status = 'ENABLED', segments.date BETWEEN '{today-30}' AND '{today}'
```

**Primary: Impression share and budget-limited detection:**
```
Resource: campaign
Fields: campaign.name, metrics.search_impression_share, metrics.search_budget_lost_impression_share, metrics.search_rank_lost_impression_share, metrics.cost_micros, metrics.conversions
Conditions: campaign.status = 'ENABLED', campaign.advertising_channel_type = 'SEARCH', segments.date BETWEEN '{today-7}' AND '{today}'
```

**Supplementary: Tracking confidence check:**
```
Resource: conversion_action
Fields: conversion_action.name, conversion_action.type, conversion_action.counting_type, conversion_action.include_in_conversions_metric, metrics.conversions
Conditions: conversion_action.status = 'ENABLED', segments.date BETWEEN '{today-30}' AND '{today}'
Orderings: metrics.conversions DESC
```

See `data/gaql-recipes.md` for additional queries.

### Date Range Fallback

If the 30-day window returns 0 rows, fall back to 90 days (`segments.date BETWEEN '{today-90}' AND '{today}'`). For budget analysis, older data is less useful — if 90 days is also empty, note "Account dormant: no activity to base budget decisions on" and recommend a plan or audit instead. Always state the date range used.

### Export Mode (no MCP)

Ask the user for:
- Campaign budget report: Budget, Spend, Conversions, Search IS%, Budget Lost IS%
- Last 30 days preferred

---

## Process
1. **Announce mode** (connected/export).
2. Before analyzing data, query the GMA Knowledge MCP: `search_both_advisors("budget allocation scaling bids minimum viable budget")` to understand what the methodology recommends.
3. **Check tracking confidence first** — from workspace findings or quick tracking check. Also query: `search_gma_training("tracking confidence budget decisions")`.
   - If tracking confidence is Low/Broken, flag that budget decisions are provisional.
   - Check `workspace/ads/drafts/_index.md` for pending tracking fix drafts.
4. Identify which buckets are buying clean signal vs. noisy traffic.
5. Assess impression share — where is budget the constraint vs. where is it quality?
6. Distinguish between budget constraints and structural/intent problems.
7. Recommend:
   - **Scale** — clean signal, budget-limited, good CPA
   - **Protect** — working well, don't starve it
   - **Reduce** — noisy traffic, poor signal, overfunded
   - **Hold** — needs more data or structural fix before budget decision
   - **Fix-before-scaling** — blocked by tracking, structure, or intent problems

## Draft Output

### Budget Reallocation Draft
**Trigger:** Analysis identifies campaigns where budget is clearly misallocated (strong campaign starved while weak campaign overfunded), AND tracking confidence is at least Medium.

Create using `drafts/templates/budget-draft.md`:
- Write to `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-budget-realloc.md`
- Include: current daily budget, proposed daily budget, change amount, reason, expected impact
- Show net budget change (budget-neutral reallocation vs. total spend change)
- Note tracking confidence gate
- Update `workspace/ads/drafts/_index.md`

### Blocking conditions
Do **not** produce a budget draft if:
- Tracking confidence is Low or Broken (recommend tracking fix instead)
- A pending tracking fix draft exists that hasn't been applied

Instead, note: "Budget decisions are blocked until tracking fix draft [X] is resolved."

### Always update workspace memory:
- `workspace/ads/findings.md` — budget observations
- `workspace/ads/learnings.md` — what we learned about spend efficiency

## Output Shape
1. **Account Status block** — account name, CID, status, date range used, tracking confidence, mode
2. Tracking gate assessment — include "What the methodology says" citation from KB
3. Budget allocation analysis (per-campaign: budget, spend, IS%, conversions) — include "What the methodology says" citation
4. Recommendations (Scale / Protect / Reduce / Hold / Fix-before-scaling)
5. Draft created (path and summary)
6. Blocked decisions (if tracking gates apply)
7. Memory updates

## Rules
- Do not scale ambiguous traffic just because volume is available.
- Do not mistake structure problems for budget problems.
- If tracking confidence is low, say that budget decisions are provisional.
- **Budget scaling is the highest-risk action in the system. Gate it behind tracking trust.**
