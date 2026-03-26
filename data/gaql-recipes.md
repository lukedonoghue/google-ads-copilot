# GAQL Recipes — Google Ads Copilot (GMA Edition)

Standard queries for each skill's data needs. All queries go through the `search` tool on the **GMA Reader MCP**.

**Important:** The GMA Reader uses structured parameters (`resource`, `fields`, `conditions`, `orderings`, `limit`), NOT raw GAQL strings. Date literals like `DURING LAST_30_DAYS` are **forbidden** — use explicit `BETWEEN` ranges.

**Date placeholders:** `{today}` and `{today-N}` mean you must calculate the actual YYYY-MM-DD dates at runtime relative to today.

---

## Account Discovery

```json
{
  "resource": "campaign",
  "fields": ["campaign.id", "campaign.name", "campaign.status", "campaign.advertising_channel_type", "campaign.bidding_strategy_type", "campaign_budget.amount_micros"],
  "conditions": ["campaign.status != 'REMOVED'"],
  "orderings": ["campaign.name ASC"]
}
```

```json
{
  "resource": "customer",
  "fields": ["customer.id", "customer.descriptive_name", "customer.currency_code", "customer.time_zone", "customer.auto_tagging_enabled"]
}
```

---

## Daily Operator (`/google-ads daily`)

```json
{
  "resource": "campaign",
  "fields": ["campaign.name", "campaign.status", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions", "metrics.conversions_value", "metrics.cost_per_conversion", "segments.date"],
  "conditions": ["segments.date BETWEEN '{today-7}' AND '{today}'", "campaign.status = 'ENABLED'"],
  "orderings": ["metrics.cost_micros DESC"]
}
```

```json
{
  "resource": "campaign",
  "fields": ["campaign.name", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions", "metrics.cost_per_conversion", "segments.date"],
  "conditions": ["segments.date BETWEEN '{today-14}' AND '{today-8}'", "campaign.status = 'ENABLED'"],
  "orderings": ["metrics.cost_micros DESC"]
}
```

---

## Search Terms (`/google-ads search-terms`)

### PMax fallback note
If `search_term_view` comes back empty but the account has active spend, check whether the top-spend campaign is `PERFORMANCE_MAX`. For PMax-heavy accounts, use a two-step fallback:
1. Resolve `campaign.id` from the campaign report.
2. Query `campaign_search_term_view` filtered to a single campaign resource string.

Important: `campaign_search_term_insight` requires a filter on a **single** `campaign_search_term_insight.campaign_id` in the conditions. It will error if queried account-wide.

```json
{
  "resource": "search_term_view",
  "fields": ["search_term_view.search_term", "search_term_view.status", "campaign.name", "ad_group.name", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions", "metrics.conversions_value", "metrics.cost_per_conversion"],
  "conditions": ["segments.date BETWEEN '{today-30}' AND '{today}'"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 500
}
```

```json
{
  "resource": "search_term_view",
  "fields": ["search_term_view.search_term", "campaign.name", "ad_group.name", "metrics.cost_micros", "metrics.clicks", "metrics.impressions"],
  "conditions": ["segments.date BETWEEN '{today-30}' AND '{today}'", "metrics.conversions = 0", "metrics.cost_micros > 10000000"],
  "orderings": ["metrics.cost_micros DESC"]
}
```

PMax fallback queries:
```json
{
  "resource": "campaign",
  "fields": ["campaign.id", "campaign.name", "campaign.advertising_channel_type", "metrics.cost_micros"],
  "conditions": ["segments.date BETWEEN '{today-30}' AND '{today}'"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 10
}
```

```json
{
  "resource": "campaign_search_term_view",
  "fields": ["campaign_search_term_view.search_term", "campaign_search_term_view.campaign"],
  "conditions": ["campaign_search_term_view.campaign = 'customers/{cid}/campaigns/{campaign_id}'", "segments.date BETWEEN '{today-30}' AND '{today}'"],
  "limit": 100
}
```

---

## Intent Map (`/google-ads intent-map`)

```json
{
  "resource": "search_term_view",
  "fields": ["search_term_view.search_term", "campaign.name", "campaign.advertising_channel_type", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions", "metrics.conversions_value", "metrics.all_conversions"],
  "conditions": ["segments.date BETWEEN '{today-30}' AND '{today}'"],
  "orderings": ["metrics.impressions DESC"],
  "limit": 1000
}
```

---

## Negatives (`/google-ads negatives`)

```json
{
  "resource": "campaign_criterion",
  "fields": ["campaign.name", "campaign_criterion.keyword.text", "campaign_criterion.keyword.match_type", "campaign_criterion.negative"],
  "conditions": ["campaign_criterion.negative = TRUE", "campaign_criterion.type = 'KEYWORD'"]
}
```

```json
{
  "resource": "shared_set",
  "fields": ["shared_set.name", "shared_set.type", "shared_set.member_count", "shared_set.status"],
  "conditions": ["shared_set.type = 'NEGATIVE_KEYWORDS'", "shared_set.status = 'ENABLED'"]
}
```

---

## Tracking (`/google-ads tracking`)

```json
{
  "resource": "conversion_action",
  "fields": ["conversion_action.id", "conversion_action.name", "conversion_action.type", "conversion_action.category", "conversion_action.status", "conversion_action.counting_type", "conversion_action.include_in_conversions_metric", "conversion_action.value_settings.default_value"],
  "conditions": ["conversion_action.status = 'ENABLED'"]
}
```

```json
{
  "resource": "conversion_action",
  "fields": ["conversion_action.name", "conversion_action.type", "conversion_action.category", "metrics.conversions", "metrics.conversions_value", "metrics.all_conversions"],
  "conditions": ["segments.date BETWEEN '{today-30}' AND '{today}'", "conversion_action.status = 'ENABLED'"],
  "orderings": ["metrics.conversions DESC"]
}
```

---

## Structure (`/google-ads structure`)

```json
{
  "resource": "ad_group",
  "fields": ["campaign.name", "campaign.advertising_channel_type", "ad_group.name", "ad_group.status", "ad_group.type", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions", "metrics.cost_per_conversion"],
  "conditions": ["campaign.status = 'ENABLED'", "ad_group.status = 'ENABLED'", "segments.date BETWEEN '{today-30}' AND '{today}'"],
  "orderings": ["campaign.name ASC", "ad_group.name ASC"]
}
```

```json
{
  "resource": "keyword_view",
  "fields": ["campaign.name", "ad_group.name", "ad_group_criterion.keyword.text", "ad_group_criterion.keyword.match_type", "ad_group_criterion.status", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions"],
  "conditions": ["campaign.status = 'ENABLED'", "ad_group.status = 'ENABLED'", "segments.date BETWEEN '{today-30}' AND '{today}'"],
  "orderings": ["campaign.name ASC", "ad_group.name ASC"]
}
```

---

## Keyword View (supplementary for search-terms, negatives, audit)

```json
{
  "resource": "keyword_view",
  "fields": ["campaign.name", "ad_group.name", "ad_group_criterion.keyword.text", "ad_group_criterion.keyword.match_type", "ad_group_criterion.status", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions", "metrics.cost_per_conversion"],
  "conditions": ["campaign.status = 'ENABLED'", "ad_group.status = 'ENABLED'", "segments.date BETWEEN '{today-30}' AND '{today}'"],
  "orderings": ["metrics.cost_micros DESC"],
  "limit": 200
}
```

**Purpose:** Cross-reference with search_term_view to understand which targeted keywords are triggering wasteful search terms.

---

## RSAs (`/google-ads rsas`)

```json
{
  "resource": "ad_group_ad",
  "fields": ["campaign.name", "ad_group.name", "ad_group_ad.ad.responsive_search_ad.headlines", "ad_group_ad.ad.responsive_search_ad.descriptions", "ad_group_ad.ad.final_urls", "ad_group_ad.policy_summary.approval_status", "metrics.impressions", "metrics.clicks", "metrics.conversions", "metrics.cost_micros"],
  "conditions": ["ad_group_ad.ad.type = 'RESPONSIVE_SEARCH_AD'", "campaign.status = 'ENABLED'", "ad_group.status = 'ENABLED'", "segments.date BETWEEN '{today-30}' AND '{today}'"]
}
```

```json
{
  "resource": "ad_group_ad_asset_view",
  "fields": ["asset.text_asset.text", "asset.type", "ad_group_ad_asset_view.performance_label", "ad_group_ad_asset_view.field_type", "campaign.name", "ad_group.name", "metrics.impressions", "metrics.clicks", "metrics.conversions"],
  "conditions": ["segments.date BETWEEN '{today-30}' AND '{today}'", "campaign.status = 'ENABLED'"],
  "orderings": ["metrics.impressions DESC"]
}
```

---

## Budget (`/google-ads budget`)

```json
{
  "resource": "campaign",
  "fields": ["campaign.name", "campaign.status", "campaign_budget.amount_micros", "campaign_budget.delivery_method", "campaign.bidding_strategy_type", "metrics.cost_micros", "metrics.conversions", "metrics.cost_per_conversion", "metrics.impressions", "metrics.search_impression_share"],
  "conditions": ["campaign.status = 'ENABLED'", "segments.date BETWEEN '{today-30}' AND '{today}'"]
}
```

```json
{
  "resource": "campaign",
  "fields": ["campaign.name", "metrics.search_impression_share", "metrics.search_budget_lost_impression_share", "metrics.search_rank_lost_impression_share", "metrics.cost_micros", "metrics.conversions"],
  "conditions": ["campaign.status = 'ENABLED'", "campaign.advertising_channel_type = 'SEARCH'", "segments.date BETWEEN '{today-7}' AND '{today}'"]
}
```

---

## PMax (`/google-ads pmax`)

```json
{
  "resource": "campaign",
  "fields": ["campaign.name", "campaign.status", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions", "metrics.conversions_value", "metrics.cost_per_conversion"],
  "conditions": ["campaign.advertising_channel_type = 'PERFORMANCE_MAX'", "campaign.status = 'ENABLED'", "segments.date BETWEEN '{today-30}' AND '{today}'"]
}
```

```json
{
  "resource": "asset_group",
  "fields": ["campaign.name", "asset_group.name", "asset_group.status", "metrics.impressions", "metrics.clicks", "metrics.cost_micros", "metrics.conversions"],
  "conditions": ["campaign.advertising_channel_type = 'PERFORMANCE_MAX'", "segments.date BETWEEN '{today-30}' AND '{today}'"]
}
```

---

## Change History (for audit and daily)

```json
{
  "resource": "change_event",
  "fields": ["change_event.change_date_time", "change_event.change_resource_type", "change_event.change_resource_name", "change_event.client_type", "change_event.user_email", "change_event.old_resource", "change_event.new_resource"],
  "conditions": ["change_event.change_date_time BETWEEN '{today-14}' AND '{today}'"],
  "orderings": ["change_event.change_date_time DESC"],
  "limit": 100
}
```

---

## Notes

- All `cost_micros` values are in micros (1,000,000 = $1.00)
- **Date literals are forbidden.** Always use `segments.date BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'`
- Custom date ranges: calculate relative to today at query time
- `LIMIT` recommended for large accounts — start with 500, adjust as needed
- Not all resource+metric combinations are valid — use `get_resource_metadata` to check
- `change_event` queries must use `LIMIT` of 10000 or less

### Date Range Fallback

If a query returns 0 rows or <$5 total spend, widen the date range:

1. Last 30 days: `BETWEEN '{today-30}' AND '{today}'`
2. Last 90 days: `BETWEEN '{today-90}' AND '{today}'`
3. Last 12 months: `BETWEEN '{today-365}' AND '{today}'`
4. No date condition (all time)

Always note which range was used in the output. See the main skill's Date Range Fallback Protocol.
