#!/usr/bin/env bash
set -euo pipefail

# Google Ads Copilot — connected-mode search term retrieval with campaign-scoped fallback.
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

extract_field_values() {
  local key="$1"
  python3 - "$key" <<'PY'
import re, sys
key = sys.argv[1]
text = sys.stdin.read()
for match in re.finditer(r'"%s":\s*("([^"]*)"|([0-9]+))' % re.escape(key), text):
    print(match.group(2) if match.group(2) is not None else match.group(3))
PY
}

classic_query_all() {
  echo "google-ads-mcp.search(customer_id:\"$CID\",resource:\"search_term_view\",fields:[\"search_term_view.search_term\",\"search_term_view.status\",\"campaign.name\",\"ad_group.name\",\"metrics.impressions\",\"metrics.clicks\",\"metrics.cost_micros\",\"metrics.conversions\",\"metrics.conversions_value\",\"metrics.cost_per_conversion\"],conditions:[\"$DATE_CONDITION\"],orderings:[\"metrics.cost_micros DESC\"],limit:100)"
}

classic_query_search_only() {
  echo "google-ads-mcp.search(customer_id:\"$CID\",resource:\"search_term_view\",fields:[\"search_term_view.search_term\",\"search_term_view.status\",\"campaign.name\",\"ad_group.name\",\"metrics.impressions\",\"metrics.clicks\",\"metrics.cost_micros\",\"metrics.conversions\",\"metrics.conversions_value\",\"metrics.cost_per_conversion\"],conditions:[\"$DATE_CONDITION\",\"campaign.advertising_channel_type = 'SEARCH'\"],orderings:[\"metrics.cost_micros DESC\"],limit:100)"
}

classic_query_minimal_for_campaign() {
  local campaign_name="$1"
  echo "google-ads-mcp.search(customer_id:\"$CID\",resource:\"search_term_view\",fields:[\"search_term_view.search_term\",\"campaign.name\",\"ad_group.name\"],conditions:[\"$DATE_CONDITION\",\"campaign.name = '$campaign_name'\"],limit:50)"
}

pmax_query_for_campaign_resource() {
  local campaign_resource="$1"
  echo "google-ads-mcp.search(customer_id:\"$CID\",resource:\"campaign_search_term_view\",fields:[\"campaign_search_term_view.search_term\",\"campaign_search_term_view.campaign\"],conditions:[\"campaign_search_term_view.campaign = '$campaign_resource'\",\"$DATE_CONDITION\"],limit:100)"
}

pmax_insight_query_for_campaign_id() {
  local campaign_id="$1"
  echo "google-ads-mcp.search(customer_id:\"$CID\",resource:\"campaign_search_term_insight\",fields:[\"campaign_search_term_insight.category_label\",\"campaign_search_term_insight.id\",\"campaign_search_term_insight.campaign_id\"],conditions:[\"campaign_search_term_insight.campaign_id = $campaign_id\",\"$DATE_CONDITION\"],limit:100)"
}

campaigns_query() {
  echo "google-ads-mcp.search(customer_id:\"$CID\",resource:\"campaign\",fields:[\"campaign.id\",\"campaign.name\",\"campaign.advertising_channel_type\",\"metrics.cost_micros\",\"metrics.clicks\",\"metrics.conversions\"],conditions:[\"$DATE_CONDITION\"],orderings:[\"metrics.cost_micros DESC\"],limit:25)"
}

has_classic_rows() {
  grep -q '"search_term_view.search_term"'
}

has_pmax_rows() {
  grep -q '"campaign_search_term_view.search_term"'
}

echo "## Retrieval Mode Probe"
echo "- Customer ID: $CID"
echo "- Date condition: $DATE_CONDITION"
echo

echo "## Classic Search Mode Attempt (account-wide)"
CLASSIC_OUT=$(call "$(classic_query_all)" 2>&1 || true)
echo "$CLASSIC_OUT"
echo
if printf '%s\n' "$CLASSIC_OUT" | has_classic_rows; then
  echo "## Result"
  echo "Classic Search mode succeeded at account scope. Use full search-term analysis."
  exit 0
fi

echo "## Classic Search Mode Attempt (SEARCH campaigns only)"
CLASSIC_SEARCH_ONLY=$(call "$(classic_query_search_only)" 2>&1 || true)
echo "$CLASSIC_SEARCH_ONLY"
echo
if printf '%s\n' "$CLASSIC_SEARCH_ONLY" | has_classic_rows; then
  echo "## Result"
  echo "Classic Search mode succeeded when restricted to SEARCH campaigns. Use full search-term analysis."
  exit 0
fi

echo "## Campaign Enumeration"
CAMPAIGNS=$(call "$(campaigns_query)")
echo "$CAMPAIGNS"
echo

mapfile -t IDS < <(printf '%s\n' "$CAMPAIGNS" | extract_field_values "campaign.id")
mapfile -t NAMES < <(printf '%s\n' "$CAMPAIGNS" | extract_field_values "campaign.name")
mapfile -t TYPES < <(printf '%s\n' "$CAMPAIGNS" | extract_field_values "campaign.advertising_channel_type")

if [[ ${#IDS[@]} -eq 0 ]]; then
  echo "## Result"
  echo "Limited visibility mode: no campaigns surfaced for the period."
  exit 0
fi

echo "## Campaign-Scoped Retrieval Attempts"
FOUND_ANY=0
for i in "${!IDS[@]}"; do
  id="${IDS[$i]}"
  name="${NAMES[$i]:-}"
  type="${TYPES[$i]:-}"
  echo "### Campaign: $name"
  echo "- ID: $id"
  echo "- Type: $type"

  if [[ "$type" == "2" ]]; then
    OUT=$(call "$(classic_query_minimal_for_campaign "$name")" 2>&1 || true)
    echo "$OUT"
    if printf '%s\n' "$OUT" | has_classic_rows; then
      FOUND_ANY=1
      echo "- Mode: Classic Search campaign-scoped retrieval succeeded"
    else
      echo "- Mode: No classic rows surfaced for this Search campaign"
    fi
  elif [[ "$type" == "10" ]]; then
    RESOURCE="customers/$CID/campaigns/$id"
    OUT=$(call "$(pmax_query_for_campaign_resource "$RESOURCE")" 2>&1 || true)
    echo "$OUT"
    INSIGHT=$(call "$(pmax_insight_query_for_campaign_id "$id")" 2>&1 || true)
    echo "$INSIGHT"
    if printf '%s\n' "$OUT" | has_pmax_rows; then
      FOUND_ANY=1
      echo "- Mode: PMax fallback succeeded"
    else
      echo "- Mode: PMax fallback returned no usable rows"
    fi
  else
    echo "- Mode: Campaign type not currently probed for term rows"
  fi
  echo

done

if [[ "$FOUND_ANY" == "1" ]]; then
  echo "## Result"
  echo "Campaign-scoped retrieval succeeded. Use the surfaced rows and report which mode produced them (Classic Search vs PMax fallback)."
else
  echo "## Result"
  echo "Limited visibility mode: campaign-scoped retrieval still did not surface enough rows. Use campaign / asset-group / tracking analysis and request a UI export for exact waste attribution."
fi
