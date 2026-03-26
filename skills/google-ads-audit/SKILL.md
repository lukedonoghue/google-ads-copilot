---
name: google-ads-audit
description: >
  Full Google Ads review that synthesizes tracking, search terms, intent mapping, negatives,
  structure, RSAs, budget decisions, and PMax context into a single operator read.
  Pulls live data via MCP or works with manual exports. Produces a prioritized batch of
  action drafts.
---

# Google Ads Audit

This is the broad review.
Not just a checklist.
A synthesis of what the account is learning, where it is leaking, and what should change.

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/intent-map.md`
- `google-ads/references/query-patterns.md`
- `google-ads/references/negatives-playbook.md`
- `google-ads/references/tracking-playbook.md`
- `google-ads/references/structure-playbook.md`
- `google-ads/references/rsa-playbook.md`
- `google-ads/references/budget-playbook.md`
- `google-ads/references/benchmarks.md`
- `google-ads/references/deliverable-templates.md`

### MCP Tools
Load before first use:
- GMA Reader: `ToolSearch("select:mcp__gma-reader__search,mcp__gma-reader__list_accessible_customers")`
- GMA Knowledge: `ToolSearch("+gma knowledge search")`

Read workspace if available:
- All `workspace/ads/` files except `assets.md` (unless creative output is needed)
- Including `workspace/ads/drafts/_index.md` — check for existing pending drafts

---

## Data Acquisition

### Connected Mode (MCP available)

The audit pulls data across all skill areas via the `search` tool on GMA Reader MCP. Run queries in this order (each feeds into the next):

**1. Account overview:**
Use the structured `search` tool:
- **resource:** `customer`
- **fields:** `customer.id, customer.descriptive_name, customer.currency_code, customer.time_zone, customer.auto_tagging_enabled`

**2. Tracking health (check trust first):**
Use the structured `search` tool:
- **resource:** `conversion_action`
- **fields:** `conversion_action.name, conversion_action.type, conversion_action.category, conversion_action.counting_type, conversion_action.include_in_conversions_metric, metrics.conversions, metrics.all_conversions`
- **conditions:** `segments.date BETWEEN '{today-30}' AND '{today}' AND conversion_action.status = 'ENABLED'`
- **orderings:** `metrics.conversions DESC`

**3. Campaign performance and structure:**
Use the structured `search` tool:
- **resource:** `campaign`
- **fields:** `campaign.name, campaign.status, campaign.advertising_channel_type, campaign.bidding_strategy_type, campaign_budget.amount_micros, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.conversions_value, metrics.cost_per_conversion, metrics.search_impression_share, metrics.search_budget_lost_impression_share`
- **conditions:** `campaign.status = 'ENABLED' AND segments.date BETWEEN '{today-30}' AND '{today}'`
- **orderings:** `metrics.cost_micros DESC`

**4. Search terms (top 500 by spend):**
Use the structured `search` tool:
- **resource:** `search_term_view`
- **fields:** `search_term_view.search_term, campaign.name, ad_group.name, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.conversions_value`
- **conditions:** `segments.date BETWEEN '{today-30}' AND '{today}'`
- **orderings:** `metrics.cost_micros DESC`
- **limit:** `500`

**Retrieval ladder** — if the search-term query returns no rows, follow the shared retrieval ladder in `data/search-term-retrieval.md`. Report the resulting `retrieval_mode` in the audit header. Mark search-term sections as "PMax visibility-limited" when operating in `pmax-fallback` mode. In `limited` mode, note the gap and request a UI export.

**5. Ad group structure:**
Use the structured `search` tool:
- **resource:** `ad_group`
- **fields:** `campaign.name, ad_group.name, ad_group.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions`
- **conditions:** `campaign.status = 'ENABLED' AND ad_group.status = 'ENABLED' AND segments.date BETWEEN '{today-30}' AND '{today}'`
- **orderings:** `campaign.name`

**6. Keyword view (targeted keywords -- cross-reference with search terms):**
Use the structured `search` tool:
- **resource:** `keyword_view`
- **fields:** `campaign.name, ad_group.name, ad_group_criterion.keyword.text, ad_group_criterion.keyword.match_type, ad_group_criterion.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions`
- **conditions:** `campaign.status = 'ENABLED' AND ad_group.status = 'ENABLED' AND segments.date BETWEEN '{today-30}' AND '{today}'`
- **orderings:** `metrics.cost_micros DESC`
- **limit:** `200`

**7. Existing negatives:**
Use the structured `search` tool:
- **resource:** `campaign_criterion`
- **fields:** `campaign.name, campaign_criterion.keyword.text, campaign_criterion.keyword.match_type`
- **conditions:** `campaign_criterion.negative = TRUE AND campaign_criterion.type = 'KEYWORD'`

**8. RSA assets (if time permits):**
Use the structured `search` tool:
- **resource:** `ad_group_ad_asset_view`
- **fields:** `asset.text_asset.text, asset.type, ad_group_ad_asset_view.performance_label, ad_group_ad_asset_view.field_type, campaign.name, metrics.impressions, metrics.clicks, metrics.conversions`
- **conditions:** `segments.date BETWEEN '{today-30}' AND '{today}' AND campaign.status = 'ENABLED'`
- **orderings:** `metrics.impressions DESC`

See `data/gaql-recipes.md` for additional/variant queries.

### Date Range Fallback

All date-ranged queries above default to a 30-day window (`BETWEEN '{today-30}' AND '{today}'`). If results are empty or near-zero (<$5 total spend):

1. Re-run with a 90-day window (`BETWEEN '{today-90}' AND '{today}'`)
2. If still empty, re-run without a date filter (all-time)
3. **Always state the date range used** in the output header
4. **If fallback was needed**, note: "Account dormant — using [range] for historical context"

This prevents reporting "no data" on paused or seasonal accounts that have useful history.

### Export Mode (no MCP)

Ask the user for as much as they can provide:
- Campaign overview (last 30 days)
- Search Terms report (last 30 days, top 200+)
- Conversion actions list
- Current negative keyword list
- RSA asset report (optional)
- Any notes on tracking, recent changes, or known issues

The audit works with partial data — it will note confidence limitations.

---

## Audit Order

### 1. Can we trust the account?
**KB query:** `search_both_advisors("conversion tracking setup primary secondary actions")`

If tracking is weak, say so immediately. Assign tracking confidence level (High/Medium/Low/Broken).
Note which downstream conclusions are conditional on tracking trust.
Include **"What the methodology says:"** citation from KB results.

### 2. What is the account learning about buyer intent?
**KB query:** `search_both_advisors("search term analysis intent classification negative keywords")`

Summarize the query and intent reality. Build or update the Intent Map.
Note where intent classes are well-routed vs. poorly routed.
Include **"What the methodology says:"** citation from KB results.

### 3. Where is waste leaking spend?
**KB query:** `search_both_advisors("wasted spend identification zero conversion search terms")`

Identify junk, ambiguity, and routing failures. Quantify the waste.
Separate "waste from bad queries" from "waste from bad structure."
Include **"What the methodology says:"** citation from KB results.

### 4. What should be negative vs. isolated vs. already wrongly negated?
**KB query:** `search_both_advisors("negative keyword management scope match type selection")`

Distinguish exclusion from structure problems.
Default to isolation when in doubt.
**Also review existing negatives for harm:** Check if any current negatives are blocking traffic that matches the business's services. Smart campaign auto-negatives and inherited negatives are common culprits. If harmful negatives are found, include a "Negatives to Remove" section in the negative draft.
Include **"What the methodology says:"** citation from KB results.

### 5. What structure changes matter most?
**KB query:** `search_both_advisors("campaign structure intent separation ad group design")`

Focus on where meaning is being mixed.
Prioritize by spend impact, not by cosmetic neatness.
Include **"What the methodology says:"** citation from KB results.

### 6. Are RSAs aligned with buyer language?
**KB query:** `search_both_advisors("RSA composition headlines buyer language ad copy")`

Check whether ads reflect real intent and LP promise.
Note specific gaps between search language and ad copy.
Include **"What the methodology says:"** citation from KB results.

### 7. What deserves more budget, less budget, or no touch yet?
**KB query:** `search_both_advisors("budget allocation scaling winning campaigns")`

Make support/protect/reduce/hold decisions.
**Gate budget scaling behind tracking confidence.**
Include **"What the methodology says:"** citation from KB results.

### 8. Are landing pages converting (or do they look like they should be)?
**KB query:** `search_both_advisors("landing page CRO message match conversion rate")`

When conversion rates look suspiciously low, run a quick Fork A check (tracking) before blaming the landing page. If clicks are high but conversions are near-zero, the tag may not be firing -- not the page's fault. For full landing page -> conversion path diagnosis, delegate to `/google-ads landing-review`. See `skills/google-ads-landing-review/SKILL.md` and `google-ads/references/landing-page-playbook.md`.
Include **"What the methodology says:"** citation from KB results.

### 9. Is PMax helping or contaminating signal?
**KB query:** `search_both_advisors("Performance Max optimization brand exclusions feeder")`

Be explicit about inference vs. direct evidence.
Check for branded/high-intent cannibalization.
Include **"What the methodology says:"** citation from KB results.

## Draft Output

### Prioritized Draft Batch
The audit produces **multiple drafts** organized by priority. Not everything needs fixing at once.

**Priority tiers:**
1. **Fix first** — tracking problems that gate everything else
2. **Quick wins** — clear negatives that stop obvious waste
3. **Strategic moves** — structure changes, budget reallocation
4. **Refinement** — RSA refreshes, minor optimizations

For each tier with actionable findings, create a draft:
- Tracking fixes → `drafts/templates/tracking-draft.md` → `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-tracking-fix.md`
- Negatives → `drafts/templates/negative-draft.md` → `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-negatives.md`
- Structure → `drafts/templates/structure-draft.md` → `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-structure.md`
- Budget → `drafts/templates/budget-draft.md` → `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-budget-realloc.md`
- RSAs → `drafts/templates/rsa-draft.md` → `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-rsa-refresh.md`
- Landing page → `drafts/templates/landing-review-draft.md` → `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-landing-review.md`

**Cross-reference dependencies between drafts.** E.g., "Apply tracking fix before budget scaling."

Update `workspace/ads/drafts/_index.md` with all new drafts.
If 2 or more drafts are created in the same audit run, also write `workspace/ads/drafts/_batch-YYYY-MM-DD-[account-slug].md` with:
- Account, date range, and tracking confidence
- Drafts created in that run grouped by priority tier
- Dependency chain and recommended review order
- Quick-apply candidates

Do not list the `_batch-*.md` packet in `_index.md`. It is an audit packet, not a draft.

### Always update workspace memory:
- `workspace/ads/intent-map.md` — build or update from search terms
- `workspace/ads/findings.md` — audit findings log
- `workspace/ads/negatives.md` — recommended negatives
- `workspace/ads/learnings.md` — what we learned
- `workspace/ads/account.md` — account context if this is first audit

## Output Shape
1. **Account Status block** — account name, CID, status (active/suspended/dormant), date range used, tracking confidence, mode
2. **Executive summary** — 3-5 sentences: biggest issues, tracking trust, top priority
3. Tracking confidence detail (High/Medium/Low/Broken)
4. Intent landscape (brief Intent Map)
5. Waste analysis (quantified)
6. Structure assessment
7. RSA alignment check
8. Budget posture
9. PMax assessment
10. **Prioritized action plan** — organized by tier
11. Drafts created (list with paths, summaries, and dependencies)
12. Confidence assessment
13. Memory updates

## Rules
- Tracking trust comes first. Everything else is conditional.
- Search behavior beats generic advice.
- Distinguish symptoms from root causes.
- Do not bury the highest-leverage decision.
- Use benchmarks as context, not as authority.
- **The audit is the highest-value skill in the system. It should produce the clearest, most actionable output. Every finding should either become a draft or be explicitly marked as "no action needed."**
- **Prioritize ruthlessly. An audit that recommends 30 equally-weighted changes is useless. An audit that identifies the 3 things that matter most is gold.**
