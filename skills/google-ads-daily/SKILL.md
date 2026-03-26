---
name: google-ads-daily
description: >
  Daily operator review for Google Ads. Surfaces what changed, where waste is showing up,
  where signal is emerging, what is ready to scale, and what should be left alone.
  Pulls live data via MCP or works with manual exports.
---

# Google Ads Daily Operator

### MCP Tools
Load before first use:
- GMA Reader: `ToolSearch("select:mcp__gma-reader__search,mcp__gma-reader__list_accessible_customers")`
- GMA Knowledge: `ToolSearch("+gma knowledge search")`

### Knowledge Base Queries
At the start of the daily review, query the methodology for context:
- `search_gma_training("daily review Google Ads what to check first")`

Only query KB further when surfacing findings that need methodology backing.

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/query-patterns.md`
- `google-ads/references/tracking-playbook.md`
- `google-ads/references/structure-playbook.md`
- `google-ads/references/deliverable-templates.md`

Read workspace if available:
- `workspace/ads/account.md`
- `workspace/ads/goals.md`
- `workspace/ads/winners.md`
- `workspace/ads/findings.md`
- `workspace/ads/change-log.md`
- `workspace/ads/learnings.md`
- `workspace/ads/drafts/_index.md` — check for pending drafts to surface

## The 5 Daily Questions
1. Can we trust the account today?
2. Where is waste showing up?
3. Where is signal emerging?
4. What is ready to scale or isolate?
5. What should we not touch yet?

---

## Data Acquisition

### Connected Mode (MCP available)

Pull these queries via the `search` tool on the GMA Reader MCP. Use the structured `search(resource, fields, conditions, orderings, limit)` format.

**Campaign performance — last 7 days:**
```
Resource: campaign
Fields: campaign.name, campaign.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.conversions_value, metrics.cost_per_conversion, segments.date
Conditions: segments.date BETWEEN '{today-7}' AND '{today}', campaign.status = 'ENABLED'
Orderings: metrics.cost_micros DESC
```

**Recent account changes:**
```
Resource: change_event
Fields: change_event.change_date_time, change_event.change_resource_type, change_event.change_resource_name, change_event.client_type, change_event.user_email, change_event.old_resource, change_event.new_resource
Conditions: change_event.change_date_time BETWEEN '{today-7}' AND '{today}'
Orderings: change_event.change_date_time DESC
Limit: 50
```
Note: `change_event` requires `DURING` syntax — this is an API-level constraint; BETWEEN is not supported for this resource.

**Budget-limited detection (search campaigns):**
```
Resource: campaign
Fields: campaign.name, metrics.search_impression_share, metrics.search_budget_lost_impression_share, metrics.search_rank_lost_impression_share, metrics.cost_micros, metrics.conversions
Conditions: campaign.status = 'ENABLED', campaign.advertising_channel_type = 'SEARCH', segments.date BETWEEN '{today-7}' AND '{today}'
```

For prior-period comparison, run the campaign performance query with `BETWEEN` dates for the preceding 7 days.

See `data/gaql-recipes.md` for additional queries.

### Date Range Fallback

If the 7-day window returns 0 rows, fall back to 14 days (`segments.date BETWEEN '{today-14}' AND '{today}'`), then 30 days (`segments.date BETWEEN '{today-30}' AND '{today}'`). For daily reviews, don't go further back — instead note "Account dormant: no activity in the last 30 days" and recommend running a full audit with historical data. Always state the date range used.

### Export Mode (no MCP)

Ask the user for:
- Campaign overview: last 7 days (Campaign, Status, Impressions, Clicks, Cost, Conversions, CPA)
- Any recent change history
- Optionally: impression share data

See `data/export-formats.md` for recommended export format.

---

## Process
1. **Announce mode** (connected/export) at the start.
2. Before analyzing data, query the GMA Knowledge MCP to understand what the methodology recommends for daily reviews.
3. Pull or review current data snapshot.
4. Compare against goals and recent changes.
5. **Highlight deltas, not everything.** Focus on what changed since last check.
6. Use the operator summary template from `deliverable-templates.md`.
7. Check `workspace/ads/drafts/_index.md` — surface any pending drafts that need review.
8. Append meaningful notes to `workspace/ads/findings.md` if something new matters.

## Draft Output
The daily review **does not usually produce new drafts** — its job is to surface what matters and flag urgency. However:

- If it identifies an **urgent waste problem** (e.g., $200+ burned on junk queries overnight), create a quick negative draft using `drafts/templates/negative-draft.md`
- If it identifies a **budget emergency** (e.g., strong campaign exhausting budget by noon), create a budget draft using `drafts/templates/budget-draft.md`
- Always **surface existing pending drafts** from the index — "You have 3 pending drafts awaiting review"

Threshold for daily-triggered drafts: only when the finding is time-sensitive enough that waiting for the next scheduled analysis would waste significant spend.

## Output Shape
1. **Account Status block** — account name, CID, status, date range used, tracking confidence, mode
2. What changed (deltas, not full state)
3. Trust check (is tracking still clean?)
4. Waste flag (any new leaks?) — include "What the methodology says" citation if KB was queried
5. Signal flag (anything emerging?) — include "What the methodology says" citation if KB was queried
6. Pending drafts to review
7. Memory updates (if any)

## Rules
- Focus on change, not static facts.
- Mention confidence if data quality is questionable.
- Do not recommend churn for the sake of activity.
- Good operators know when not to touch things.
- **Always check the draft queue — the daily is the operator's inbox.**
