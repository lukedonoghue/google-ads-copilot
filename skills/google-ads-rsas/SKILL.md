---
name: google-ads-rsas
description: >
  Generate or refine Google Ads RSA recommendations using real buyer language from search terms,
  intent clusters, and winning modifiers. Pulls live data via MCP or works with manual exports.
  Produces RSA refresh drafts.
---

# Google Ads RSAs

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/query-patterns.md`
- `google-ads/references/intent-map.md`
- `google-ads/references/rsa-playbook.md`
- `google-ads/references/deliverable-templates.md`

Read workspace if available:
- `workspace/ads/account.md`
- `workspace/ads/goals.md`
- `workspace/ads/intent-map.md`
- `workspace/ads/queries.md`
- `workspace/ads/winners.md`
- `workspace/ads/assets.md`
- `workspace/ads/learnings.md`

### MCP Tools
Load before first use:
- GMA Reader: `ToolSearch("select:mcp__gma-reader__search,mcp__gma-reader__list_accessible_customers")`
- GMA Knowledge: `ToolSearch("+gma knowledge search")`

---

## Data Acquisition

### Connected Mode (MCP available)

Pull via the `search` tool on GMA Reader MCP:

**Primary: RSA asset performance:**
Use the structured `search` tool:
- **resource:** `ad_group_ad_asset_view`
- **fields:** `asset.text_asset.text, asset.type, ad_group_ad_asset_view.performance_label, ad_group_ad_asset_view.field_type, campaign.name, ad_group.name, metrics.impressions, metrics.clicks, metrics.conversions`
- **conditions:** `segments.date BETWEEN '{today-30}' AND '{today}' AND campaign.status = 'ENABLED'`
- **orderings:** `metrics.impressions DESC`

**Supplementary: Search terms (for buyer language extraction):**
Use the structured `search` tool:
- **resource:** `search_term_view`
- **fields:** `search_term_view.search_term, campaign.name, metrics.conversions, metrics.clicks, metrics.cost_micros`
- **conditions:** `segments.date BETWEEN '{today-30}' AND '{today}' AND metrics.conversions > 0`
- **orderings:** `metrics.conversions DESC`
- **limit:** `200`

**Retrieval ladder** — if the search-term query returns no rows, follow the shared retrieval ladder in `data/search-term-retrieval.md`. In `pmax-fallback` mode, use rows for buyer-language extraction only (language signal, not per-term performance). In `limited` mode, rely on existing asset performance data for copy direction.

**Supplementary: RSA ad-level data:**
Use the structured `search` tool:
- **resource:** `ad_group_ad`
- **fields:** `campaign.name, ad_group.name, ad_group_ad.ad.responsive_search_ad.headlines, ad_group_ad.ad.responsive_search_ad.descriptions, ad_group_ad.ad.final_urls, metrics.impressions, metrics.clicks, metrics.conversions`
- **conditions:** `ad_group_ad.ad.type = 'RESPONSIVE_SEARCH_AD' AND campaign.status = 'ENABLED' AND segments.date BETWEEN '{today-30}' AND '{today}'`

See `data/gaql-recipes.md` for additional queries.

### Export Mode (no MCP)

Ask the user for:
- RSA asset report (headlines, descriptions, performance labels)
- Or RSA preview from the ads tab
- Search terms report (for buyer language extraction)

---

## Process
1. **Announce mode** (connected/export).
2. **Query knowledge base before analysis:**
   - `search_both_advisors("RSA composition headlines buyer language ad copy")`
   - For pin strategy: `search_ppc_copilot("RSA pinning strategy headline position importance")`
   - For buyer language: `search_both_advisors("using search term language in ad copy buyer words")`
3. Identify the target query cluster or intent bucket.
4. For search-term buyer language, run the shared retrieval ladder (`data/search-term-retrieval.md`). In `pmax-fallback`, use rows for language extraction only. In `limited`, rely on asset performance data.
5. Extract buyer language and repeated modifiers from converting search terms when available, or from PMax query rows when only language visibility is available.
6. Review current RSA assets: what's BEST, GOOD, LOW, UNRATED?
7. Determine the core promise and LP fit.
8. Recommend RSA components: headline themes, description angles, message hierarchy.
9. Save outputs to workspace memory.

## Draft Output

### RSA Refresh Draft
**Trigger:** Analysis shows (a) LOW-performing assets that could be replaced, or (b) buyer language patterns not represented in current ads.

Create using `drafts/templates/rsa-draft.md`:
- Write to `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-rsa-refresh.md`
- Include specific headlines (≤30 chars) and descriptions (≤90 chars)
- Note pin recommendations (use sparingly)
- Note which assets to consider removing and why
- Source each new asset to the buyer language it came from
- Update `workspace/ads/drafts/_index.md`

### Always update workspace memory:
- `workspace/ads/assets.md` — current asset inventory and new recommendations
- `workspace/ads/winners.md` — high-performing query language
- `workspace/ads/queries.md` — buyer language patterns

## Rules
- Do not write generic ads for mixed intent.
- Use real query language where possible.
- Keep LP alignment explicit.
- If the intent bucket is weak or noisy, say so before generating ads.
