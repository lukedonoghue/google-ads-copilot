#!/usr/bin/env bash
set -euo pipefail

# Google Ads Copilot — connected-mode search term retrieval with PMax fallback.
#
# Usage:
#   source data/google-ads-mcp.test.env.sh
#   ./scripts/search-terms-fallback.sh <customer-id> [date-condition]
#
# Examples:
#   ./scripts/search-terms-fallback.sh 8468311086
#   ./scripts/search-terms-fallback.sh 8468311086 "segments.date BETWEEN '2026-01-19' AND '2026-03-19'"

CID="${1:-}"
DATE_CONDITION="${2:-segments.date DURING LAST_30_DAYS}"

if [[ -z "$CID" ]]; then
  echo "Usage: $0 <customer-id> [date-condition]" >&2
  exit 1
fi

call() {
  mcporter call "$1"
}

extract_first_number() {
  sed -n "s/.*\"$1\": \([0-9][0-9]*\).*/\1/p" | head -1
}

extract_first_string() {
  local key="$1"
  python3 - "$key" <<'PY'
import re, sys
key = sys.argv[1]
text = sys.stdin.read()
match = re.search(r'"%s": "([^"]*)"' % re.escape(key), text)
if match:
    print(match.group(1))
PY
}

CLASSIC_QUERY="google-ads-mcp.search(customer_id:\"$CID\",resource:\"search_term_view\",fields:[\"search_term_view.search_term\",\"search_term_view.status\",\"campaign.name\",\"ad_group.name\",\"metrics.impressions\",\"metrics.clicks\",\"metrics.cost_micros\",\"metrics.conversions\",\"metrics.conversions_value\",\"metrics.cost_per_conversion\"],conditions:[\"$DATE_CONDITION\"],orderings:[\"metrics.cost_micros DESC\"],limit:100)"

TOP_CAMPAIGNS_QUERY="google-ads-mcp.search(customer_id:\"$CID\",resource:\"campaign\",fields:[\"campaign.id\",\"campaign.name\",\"campaign.advertising_channel_type\",\"metrics.cost_micros\",\"metrics.clicks\",\"metrics.conversions\"],conditions:[\"$DATE_CONDITION\"],orderings:[\"metrics.cost_micros DESC\"],limit:10)"

echo "## Retrieval Mode Probe"
echo "- Customer ID: $CID"
echo "- Date condition: $DATE_CONDITION"
echo

echo "## Classic Search Mode Attempt"
CLASSIC_OUT=$(call "$CLASSIC_QUERY" 2>&1 || true)
echo "$CLASSIC_OUT"
echo

if printf '%s\n' "$CLASSIC_OUT" | grep -q '"search_term_view.search_term"'; then
  echo "## Result"
  echo "Classic Search mode succeeded. Use full search-term analysis."
  exit 0
fi

echo "## Top Campaign Detection"
TOP=$(call "$TOP_CAMPAIGNS_QUERY")
echo "$TOP"
echo

TOP_TYPE=$(printf '%s\n' "$TOP" | extract_first_number "campaign.advertising_channel_type")
TOP_ID=$(printf '%s\n' "$TOP" | extract_first_number "campaign.id")
TOP_NAME=$(printf '%s\n' "$TOP" | extract_first_string "campaign.name")

if [[ -z "$TOP_ID" ]]; then
  echo "## Result"
  echo "Limited visibility mode: no active campaigns surfaced for the period."
  exit 0
fi

if [[ "$TOP_TYPE" != "10" ]]; then
  echo "## Result"
  echo "Classic Search mode returned no rows, but the top campaign is not PMax. Treat as limited visibility and ask for a UI export."
  exit 0
fi

CAMPAIGN_RESOURCE="customers/$CID/campaigns/$TOP_ID"
PMAX_VIEW_QUERY="google-ads-mcp.search(customer_id:\"$CID\",resource:\"campaign_search_term_view\",fields:[\"campaign_search_term_view.search_term\",\"campaign_search_term_view.campaign\"],conditions:[\"campaign_search_term_view.campaign = '$CAMPAIGN_RESOURCE'\",\"$DATE_CONDITION\"],limit:100)"
PMAX_INSIGHT_QUERY="google-ads-mcp.search(customer_id:\"$CID\",resource:\"campaign_search_term_insight\",fields:[\"campaign_search_term_insight.category_label\",\"campaign_search_term_insight.id\",\"campaign_search_term_insight.campaign_id\"],conditions:[\"campaign_search_term_insight.campaign_id = $TOP_ID\",\"$DATE_CONDITION\"],limit:100)"

echo "## PMax Fallback Mode"
echo "- Top campaign: $TOP_NAME"
echo "- Campaign ID: $TOP_ID"
echo "- Campaign resource: $CAMPAIGN_RESOURCE"
echo

echo "### campaign_search_term_view"
PMAX_ROWS=$(call "$PMAX_VIEW_QUERY" 2>&1 || true)
echo "$PMAX_ROWS"
echo

echo "### campaign_search_term_insight"
PMAX_INSIGHT=$(call "$PMAX_INSIGHT_QUERY" 2>&1 || true)
echo "$PMAX_INSIGHT"
echo

if printf '%s\n' "$PMAX_ROWS" | grep -q '"campaign_search_term_view.search_term"'; then
  echo "## Result"
  echo "PMax fallback mode succeeded. Query rows are available, but term-level metrics may be limited compared with classic Search mode."
else
  echo "## Result"
  echo "Limited visibility mode: PMax fallback did not return usable query rows. Use campaign / asset-group / tracking analysis and request a UI export for exact waste attribution."
fi
