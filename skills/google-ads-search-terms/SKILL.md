---
name: google-ads-search-terms
description: >
  Analyze a Google Ads search terms report for waste, buyer-intent signals, negative candidates,
  isolation opportunities, and messaging clues. Pulls live data via MCP or works with manual exports.
  Produces negative keyword drafts and RSA drafts when findings warrant.
---

# Google Ads Search Terms Review

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/query-patterns.md`
- `google-ads/references/intent-map.md`
- `google-ads/references/negatives-playbook.md`
- `google-ads/references/deliverable-templates.md`

Read workspace if available:
- `workspace/ads/account.md`
- `workspace/ads/goals.md`
- `workspace/ads/intent-map.md`
- `workspace/ads/queries.md`
- `workspace/ads/negatives.md`
- `workspace/ads/learnings.md`

---

## Data Acquisition

### Connected Mode (MCP available)

Pull via the `search` tool on `google-ads-mcp`:

**Primary: Search terms report — last 30 days, by spend:**
```sql
SELECT
  search_term_view.search_term,
  search_term_view.status,
  campaign.name,
  ad_group.name,
  metrics.impressions,
  metrics.clicks,
  metrics.cost_micros,
  metrics.conversions,
  metrics.conversions_value,
  metrics.cost_per_conversion
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
LIMIT 500
```

**PMax fallback protocol — required when Search rows come back empty but spend is active:**
1. Pull top campaigns for the period.
2. If the top-spend active campaign is `PERFORMANCE_MAX`, switch to PMax fallback mode.
3. Resolve the specific PMax `campaign.id` first.
4. Query `campaign_search_term_view` filtered to that single campaign resource.
5. If available, also probe `campaign_search_term_insight` **with a single-campaign filter**. Google requires `campaign_search_term_insight.campaign_id = <id>` in the WHERE clause.
6. If rows are returned but metrics are not available on that surface, say so explicitly and return **query-row visibility only** plus campaign / asset-group context. Do not pretend you have classic Search-term cost-per-term detail when you do not.

**PMax fallback example:**
```sql
-- Step 1: resolve the PMax campaign id
SELECT
  campaign.id,
  campaign.name,
  campaign.advertising_channel_type,
  metrics.cost_micros
FROM campaign
WHERE segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
LIMIT 10

-- Step 2: pull campaign-scoped PMax search query rows
SELECT
  campaign_search_term_view.search_term,
  campaign_search_term_view.campaign
FROM campaign_search_term_view
WHERE campaign_search_term_view.campaign = 'customers/1234567890/campaigns/23456012538'
  AND segments.date DURING LAST_30_DAYS
LIMIT 100

-- Step 3: optional insight probe (single campaign filter required)
SELECT
  campaign_search_term_insight.category_label,
  campaign_search_term_insight.id,
  campaign_search_term_insight.campaign_id
FROM campaign_search_term_insight
WHERE campaign_search_term_insight.campaign_id = 23456012538
  AND segments.date DURING LAST_30_DAYS
LIMIT 100
```

**Supplementary: High-spend zero-conversion terms (waste hunt):**
```sql
SELECT
  search_term_view.search_term,
  campaign.name,
  ad_group.name,
  metrics.cost_micros,
  metrics.clicks,
  metrics.impressions
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS
  AND metrics.conversions = 0
  AND metrics.cost_micros > 10000000
ORDER BY metrics.cost_micros DESC
```

**Supplementary: Keyword view (cross-reference with targeted keywords):**
```sql
SELECT
  campaign.name,
  ad_group.name,
  ad_group_criterion.keyword.text,
  ad_group_criterion.keyword.match_type,
  ad_group_criterion.status,
  metrics.impressions,
  metrics.clicks,
  metrics.cost_micros,
  metrics.conversions,
  metrics.cost_per_conversion
FROM keyword_view
WHERE campaign.status = 'ENABLED'
  AND ad_group.status = 'ENABLED'
  AND segments.date DURING LAST_30_DAYS
ORDER BY metrics.cost_micros DESC
LIMIT 200
```

**Why keyword_view matters for search-terms analysis:**
- Shows which *targeted* keywords triggered the search terms you're reviewing
- Reveals match type expansion: a broad match keyword "recycling" triggering "beer can recycling near me"
- Identifies keywords that are generating disproportionate waste (the keyword is the problem, not just the search term)
- Informs whether the fix is a negative keyword or a keyword match type change
- Cross-reference: if a wasteful search term comes from a single broad-match keyword, narrowing or pausing that keyword may be better than adding negatives

**Supplementary: Existing negatives (to avoid duplicates):**
```sql
SELECT
  campaign.name,
  campaign_criterion.keyword.text,
  campaign_criterion.keyword.match_type,
  campaign_criterion.negative
FROM campaign_criterion
WHERE campaign_criterion.negative = TRUE
  AND campaign_criterion.type = 'KEYWORD'
```

See `data/gaql-recipes.md` for additional queries.

### Date Range Fallback

If `LAST_30_DAYS` returns 0 rows or <$5 total spend, fall back to `LAST_90_DAYS`, then all-time (no date filter). Always state the date range used in the output. See the main skill's Date Range Fallback Protocol for details.

### Export Mode (no MCP)

Ask the user for:
- Search Terms report: last 30 days
- Columns needed: Search term, Campaign, Ad group, Impressions, Clicks, Cost, Conversions, Conv. value
- Sort by Cost descending
- Include at least top 200-500 terms

Also request existing negative keyword list if available.

See `data/export-formats.md` for recommended format.

---

## Process
1. **Announce mode** (connected/export).
2. In connected mode, try the classic Search path first.
3. If `search_term_view` returns empty but the account has active spend, inspect top campaigns for the period.
4. If spend is concentrated in `PERFORMANCE_MAX`, switch to **PMax fallback mode** using `campaign_search_term_view` and campaign-scoped `campaign_search_term_insight`.
5. If PMax fallback returns rows but not rich term-level metrics, say so explicitly and continue in **query-row visibility mode** instead of failing empty.
6. Review terms by spend, conversions, CPA/ROAS, and recurring modifiers when those metrics are available.
7. Group terms into meaningful clusters (buyer intent, comparison, informational, junk, branded).
8. Cross-reference against existing negatives — don't re-recommend what's already excluded.
9. **Cross-reference against keyword_view** when keyword rows exist — identify which targeted keywords triggered wasteful search terms. If a single broad-match keyword is responsible for multiple waste clusters, recommend narrowing/pausing that keyword alongside (or instead of) adding negatives.
10. Cross-reference against the Intent Map — update it if new patterns emerge.
11. Identify:
   - **Keep/scale** — high-intent, converting, efficient
   - **Isolate** — different intent class, needs its own bucket
   - **Exclude** — clear waste, no plausible path to conversion
   - **Watchlist** — ambiguous, needs more data
9. Extract messaging clues from high-value language (feeds RSA recommendations).
10. Recommend safest negative match type + scope where warranted.
11. Use the deliverable templates for operator summary + negative recommendations.
12. Update workspace memory files.

## Draft Output

### Negative Keyword Draft
**Trigger:** 3+ clear waste terms identified with combined spend > $50 (or any single term > $25 waste).

Create a draft using `drafts/templates/negative-draft.md`:
- Write to `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-negatives.md`
- Include every recommended negative with: keyword, match type, scope, reason, spend wasted, collateral risk
- Update `workspace/ads/drafts/_index.md`

### RSA Draft
**Trigger:** Clear buyer language patterns identified that differ from current ad copy.

Create a draft using `drafts/templates/rsa-draft.md`:
- Write to `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-rsa-refresh.md`
- Include specific headlines/descriptions derived from converting query language
- Update `workspace/ads/drafts/_index.md`

### Always update workspace memory:
- `workspace/ads/queries.md` — notable patterns and clusters
- `workspace/ads/intent-map.md` — if new intent classes emerge
- `workspace/ads/negatives.md` — recommended negatives (even before draft approval)
- `workspace/ads/findings.md` — strategic observations

## Output Shape
1. **Account Status block** — account name, CID, status, date range used, tracking confidence, mode
2. Data summary (terms analyzed, date range, total spend covered)
3. Retrieval mode note:
   - **Classic Search mode** — full search-term metrics available
   - **PMax fallback mode** — query rows available, but term-level metrics may be limited
   - **Limited visibility mode** — Google exposed insufficient query detail; shift to inference and operator next step
4. Cluster analysis (intent groups with performance)
5. Waste identification (specific terms, amounts, patterns)
6. Signal identification (buyer language, emerging opportunities)
7. Isolation opportunities (intent that deserves its own bucket)
8. Messaging clues (language for RSA recommendations)
9. Confidence assessment
10. Drafts created (with paths and summaries)
11. Memory updates

## Rules
- Do not recommend broad negatives casually.
- Do not call something junk just because it has low volume.
- Distinguish poor execution from poor intent.
- Favor cluster-level interpretation over row-by-row trivia.
- **Always produce a negative draft when waste is clear. Do not leave actionable negatives buried in analysis prose.**
- **Cross-check existing negatives before recommending — duplicates waste operator trust.**
