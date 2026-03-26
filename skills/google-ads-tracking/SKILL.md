---
name: google-ads-tracking
description: >
  Diagnose whether a Google Ads account's conversion tracking is trustworthy enough to optimize.
  Pulls live data via MCP or works with manual exports. Produces tracking fix drafts when
  problems are found.
---

# Google Ads Tracking

### MCP Tools
Load before first use:
- GMA Reader: `ToolSearch("select:mcp__gma-reader__search,mcp__gma-reader__list_accessible_customers")`
- GMA Knowledge: `ToolSearch("+gma knowledge search")`

### Knowledge Base Queries
- Before diagnostic: `search_both_advisors("conversion tracking setup primary secondary counting")`
- For duplicate detection: `search_ppc_copilot("duplicate conversion tracking GA4 import")`

Before analyzing the data, query the GMA Knowledge MCP to understand what the methodology recommends for conversion tracking diagnostics.

Read first:
- `google-ads/references/operator-thesis.md`
- `google-ads/references/tracking-playbook.md`
- `google-ads/references/deliverable-templates.md`

Read workspace if available:
- `workspace/ads/account.md`
- `workspace/ads/goals.md`
- `workspace/ads/findings.md`
- `workspace/ads/change-log.md`
- `workspace/ads/learnings.md`

---

## Data Acquisition

### Connected Mode (MCP available)

Pull via the `search` tool on the GMA Reader MCP. Use the structured `search(resource, fields, conditions, orderings, limit)` format.

**Primary: Conversion actions and configuration:**
```
Resource: conversion_action
Fields: conversion_action.id, conversion_action.name, conversion_action.type, conversion_action.category, conversion_action.status, conversion_action.counting_type, conversion_action.include_in_conversions_metric, conversion_action.value_settings.default_value
Conditions: conversion_action.status = 'ENABLED'
```

**Primary: Conversion performance by action (detect duplicates/pollution):**
```
Resource: conversion_action
Fields: conversion_action.name, conversion_action.type, conversion_action.category, metrics.conversions, metrics.conversions_value, metrics.all_conversions
Conditions: segments.date BETWEEN '{today-30}' AND '{today}', conversion_action.status = 'ENABLED'
Orderings: metrics.conversions DESC
```

**Supplementary: Account auto-tagging status:**
```
Resource: customer
Fields: customer.id, customer.descriptive_name, customer.auto_tagging_enabled
```

**Supplementary: Campaign-level conversion metrics (look for anomalies):**
```
Resource: campaign
Fields: campaign.name, metrics.conversions, metrics.all_conversions, metrics.conversions_value, metrics.cost_micros, metrics.cost_per_conversion
Conditions: campaign.status = 'ENABLED', segments.date BETWEEN '{today-30}' AND '{today}'
Orderings: metrics.conversions DESC
```

See `data/gaql-recipes.md` for additional queries.

### Date Range Fallback

Conversion action configuration queries (no date range) always work. For conversion *performance* queries, if the 30-day window returns zero data, fall back to 90 days (`segments.date BETWEEN '{today-90}' AND '{today}'`), then all-time. Configuration queries don't need fallback — they reflect current state regardless. Always state the date range used.

### Export Mode (no MCP)

Ask the user for:
- Conversion actions list (name, type, counting, include in conversions, value settings)
- Google Tag Assistant screenshot or diagnosis notes
- GA4 conversion import settings (if applicable)
- Any notes on tracking implementation

See `data/export-formats.md` for recommended format.

---

## Diagnostic Framework

Before starting diagnostics, query the GMA Knowledge MCP: `search_both_advisors("conversion tracking setup primary secondary counting")` to understand what the methodology recommends.

For duplicate detection specifically, query: `search_ppc_copilot("duplicate conversion tracking GA4 import")`.

### 1. Can we trust the account?
Assign a tracking confidence level immediately using the rubric in `google-ads/references/tracking-playbook.md`.

| Level | Meaning | Action |
|-------|---------|--------|
| **High** | Clean primary conversion, no duplicates, correct counting, ≥15 conv/30d | Optimize freely |
| **Medium** | Minor issues (micro-conversions in primary, 5-14 conv/30d, possible over-count) | Optimize cautiously, fix issues |
| **Low** | Major problems (duplicates, wrong counting, <5 conv/30d, polluted signal) | Fix tracking FIRST, block budget scaling |
| **Broken** | No meaningful conversion signal | Stop. Fix tracking. Nothing else matters. |

**Threshold checklist (from tracking-playbook.md):**
- Count primary conversion actions (should be 1-2 clear ones)
- Check `include_in_conversions_metric` — are micro-conversions polluting primary?
- Compare `conversions` vs `all_conversions` — if ratio is >2x, investigate
- Check counting type — "One" for leads, "Every" for e-commerce only
- Check for duplicate sources — same event tracked by both native tag AND GA4 import?
- Check auto-tagging status
- Verify conversion volume (≥15/30d for HIGH, 5-14 for MEDIUM, <5 for LOW)

### 2. What to check

**Duplicate counting:**
- Same conversion tracked by both native tag AND GA4 import
- Multiple conversion actions for the same event
- "Every" counting type on lead/form events (should be "One")

**Micro-conversion pollution:**
- Page views, scroll depth, time on site set as primary conversions
- These inflate conversion count and deflate apparent CPA
- Smart bidding optimizes toward them instead of real conversions

**Missing conversions:**
- Key events not tracked at all
- Phone calls without call tracking
- Form submissions without confirmation page or event tracking

**Attribution concerns:**
- Auto-tagging disabled (GCLID not passing)
- Cross-domain tracking gaps
- Conversion window too short or too long

**Value quality:**
- All conversions have the same default value
- Values don't reflect actual revenue
- Missing value tracking on e-commerce

### 3. Impact assessment
For each problem found, assess:
- How much is this distorting reported performance?
- Which campaigns are most affected?
- Is smart bidding learning from bad signal?
- What decisions should wait until this is fixed?

## Draft Output

### Tracking Fix Draft
**Trigger:** Any tracking problem at Medium confidence or lower.

Create using `drafts/templates/tracking-draft.md`:
- Write to `workspace/ads/drafts/YYYY-MM-DD-[account-slug]-tracking-fix.md`
- Include specific fixes: what to change, current vs. proposed state
- Note the impact on reported conversions ("Conversions will appear to drop ~40%")
- Note the impact on smart bidding ("2-3 week recalibration period")
- **Critically:** list which optimization decisions should wait until tracking is fixed
- Update `workspace/ads/drafts/_index.md`

### Blocking behavior
When tracking confidence is Low or Broken, the draft should include a "blocked decisions" section that explicitly names what other skills/drafts should NOT proceed until tracking is resolved:
- Budget scaling → blocked
- Structure changes → proceed with caution
- Negatives → can proceed (waste is waste regardless of tracking)
- RSA changes → can proceed (copy quality is independent)

### Always update workspace memory:
- `workspace/ads/findings.md` — tracking diagnosis and confidence level
- `workspace/ads/account.md` — update tracking status if it has changed
- `workspace/ads/learnings.md` — what we learned about this account's tracking

## Output Shape
1. **Account Status block** — account name, CID, status, date range used, tracking confidence, mode
3. Conversion actions inventory (what's tracked, how, counting type)
4. Problems identified (with severity and evidence) — include "What the methodology says" citation per problem
5. Impact assessment (what's distorted, which campaigns affected) — include "What the methodology says" citation
6. Recommended fixes (specific changes)
7. Blocked decisions (what should wait)
8. Draft created (path and summary)
9. Memory updates

## Rules
- If tracking is unreliable, say it early.
- Do not bury trust issues under optimization tips.
- Explain what decisions should wait until tracking is fixed.
- **Tracking confidence is a gate. If it's Low or Broken, other skills should know.**
- **The most dangerous Google Ads accounts look great on paper because tracking is counting the wrong things. Surface this clearly.**
