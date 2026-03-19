#!/usr/bin/env bash
set -euo pipefail

# Backwards-compatible wrapper.
# Prefer: ./scripts/search-terms-fallback.sh <customer-id>
exec "$(dirname "$0")/search-terms-fallback.sh" "$@"
