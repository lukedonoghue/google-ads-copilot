# PMax Query Visibility

Performance Max does **not** expose search-query data like a standard Search campaign.
That means the kit needs a different operator path.

## Goal
When an account is PMax-heavy, the kit should not silently fail on `/google-ads search-terms`.
It should:
1. Detect that active spend is concentrated in PMax.
2. Attempt a PMax-specific query-row fallback.
3. Return whatever Google will actually expose.
4. Be explicit about the limits of that surface.

## Recommended behavior

### Standard Search accounts
Use the normal path:
- `search_term_view`
- `keyword_view`
- classic waste / negatives / isolation analysis

### PMax-heavy accounts
Use a different path:

#### Step 1 — Detect campaign mix
Pull top campaigns over the requested date range.
If the dominant active campaign is `PERFORMANCE_MAX`, switch the search-terms skill into **PMax fallback mode**.

#### Step 2 — Resolve the exact campaign id
`campaign_search_term_view` is campaign-scoped.
So first pull:
- `campaign.id`
- `campaign.name`
- `campaign.advertising_channel_type`

#### Step 3 — Pull query rows via `campaign_search_term_view`
Query rows can be retrieved by filtering to the specific campaign resource string:
- `customers/<cid>/campaigns/<campaign_id>`

#### Step 4 — Probe `campaign_search_term_insight`
This surface is stricter than expected.
Google requires a WHERE filter on a **single** `campaign_search_term_insight.campaign_id`.
If that insight surface is sparse or empty, do not treat it as a kit failure. Treat it as limited Google visibility.

#### Step 5 — Switch the output mode
For PMax-heavy accounts, output should become:
- **query-row visibility** where available
- **campaign / asset-group context**
- **tracking confidence**
- **waste-risk hypotheses**
- **what cannot be concluded safely**

Do **not** pretend you have the same per-term cost / CPA / conversion detail available from classic Search unless it is actually returned.

## What the kit should say

When rows are available but metrics are limited:

> Mode: Connected (PMax fallback) — Google exposed query rows for the dominant Performance Max campaign, but not the same rich per-term metrics normally available for standard Search campaigns.

When even fallback is sparse:

> Mode: Connected (PMax limited visibility) — the account is PMax-heavy and Google is exposing only limited query-level insight. Use campaign / asset-group / tracking analysis and request a UI export if exact waste attribution is needed.

## Product implication
The kit should stop treating `/google-ads search-terms` as a single universal retrieval path.
Instead it should support three operator modes:

1. **Search mode** — full query analysis
2. **PMax fallback mode** — query-row visibility + context
3. **Limited visibility mode** — explain limits, shift to inference + operator next step

## Local test result
Tested successfully against a live PMax-heavy account.
The fallback returned at least one real query row via `campaign_search_term_view`, confirming that the fallback path is valid.
