#!/bin/bash
# Run maintenance enrichment batches until all stale entries are updated
# Usage: ./supabase/scripts/run-maintenance.sh

set -e

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.local"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env.local not found at $ENV_FILE"
  exit 1
fi

# Source the env file
set -a
source "$ENV_FILE"
set +a

if [ -z "$ADMIN_API_KEY_PROD" ]; then
  echo "Error: ADMIN_API_KEY_PROD not set in .env.local"
  exit 1
fi

ENDPOINT="https://vfeovvfpivbqeziwinwz.supabase.co/functions/v1/enrich-vocabulary/maintain"
BATCH_SIZE=${1:-20}

echo "Starting maintenance enrichment (batch_size=$BATCH_SIZE)..."
echo ""

iteration=1
total_updated=0
total_failed=0

while true; do
  echo "=== Batch $iteration ==="

  response=$(curl -s -X POST "$ENDPOINT" \
    -H "Authorization: Bearer $ADMIN_API_KEY_PROD" \
    -H "Content-Type: application/json" \
    -d "{\"batch_size\": $BATCH_SIZE}")

  echo "$response"

  # Parse JSON response
  updated=$(echo "$response" | grep -o '"updated":[0-9]*' | grep -o '[0-9]*')
  failed=$(echo "$response" | grep -o '"failed":[0-9]*' | grep -o '[0-9]*')
  remaining=$(echo "$response" | grep -o '"remaining":[0-9]*' | grep -o '[0-9]*')

  if [ -z "$remaining" ]; then
    echo "Error: Invalid response or API error"
    exit 1
  fi

  total_updated=$((total_updated + updated))
  total_failed=$((total_failed + failed))

  echo ""

  if [ "$remaining" = "0" ]; then
    echo "✓ All entries updated!"
    echo ""
    echo "Summary:"
    echo "  Total updated: $total_updated"
    echo "  Total failed: $total_failed"
    break
  fi

  iteration=$((iteration + 1))
  echo "Waiting 2s before next batch..."
  sleep 2
  echo ""
done
