#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage:
  $0 [--v1] <PROPOSAL_ID> <GOV_CHAIN_LCD>
Options:
  --v1           multi-message mode (handles multiple MsgRecoverClient entries)
  -h, --help     show this help message
EOF
  exit 1
}

# ————————————————————————————————————————————————————————————————
# Parse flags
# ————————————————————————————————————————————————————————————————
V1_MODE=false
while [[ "${1:-}" =~ ^- ]]; do
  case "$1" in
    --v1)      V1_MODE=true; shift ;;
    -h|--help) usage ;;
    *)         echo "Unknown option: $1" >&2; usage ;;
  esac
done

# ————————————————————————————————————————————————————————————————
# Positional args
# ————————————————————————————————————————————————————————————————
PROP_ID=${1:-}
GOV_CHAIN_LCD=${2:-}

if [[ -z "$PROP_ID" || -z "$GOV_CHAIN_LCD" ]]; then
  usage
fi

# Color codes
COL_RED='\033[0;31m'
COL_GREEN='\033[0;32m'
COL_NC='\033[0m'

# ————————————————————————————————————————————————————————————————
# Verify gov-chain LCD
# ————————————————————————————————————————————————————————————————
check_gov_lcd() {
#   curl --connect-timeout 3 -fs \
#     "$GOV_CHAIN_LCD/cosmos/base/tendermint/v1beta1/blocks/latest" \
#     >/dev/null || {
#       echo "error fetching GOV_CHAIN_LCD: $GOV_CHAIN_LCD" >&2
#       exit 1
#     }
    echo "omitting lcd check..."
}

# ————————————————————————————————————————————————————————————————
# Verify a reference RPC endpoint
# ————————————————————————————————————————————————————————————————
check_ref_rpc() {
  local rpc=$1
  curl --connect-timeout 3 -fs "$rpc/status" >/dev/null || {
    echo "error fetching REFERENCE_CHAIN_RPC: $rpc" >&2
    exit 1
  }
}

# ————————————————————————————————————————————————————————————————
# Fetch v0 proposal (single-message)
# ————————————————————————————————————————————————————————————————
fetch_prop_data() {
  local raw
  echo "fetching proposal data..."
  raw=$(curl --connect-timeout 3 -fsS \
    "$GOV_CHAIN_LCD/cosmos/gov/v1beta1/proposals/$PROP_ID")
  echo $raw | jq
  TITLE=$(jq -r '.proposal.title // empty' <<<"$raw")
  SUMMARY=$(jq -r '.proposal.summary // empty' <<<"$raw")
  mapfile -t SUBJECT_IDS <<< "$(jq -r '.proposal.content.subject_client_id' <<<"$raw")"
  mapfile -t SUBSTITUTE_IDS <<< "$(jq -r '.proposal.content.substitute_client_id' <<<"$raw")"
}

# ————————————————————————————————————————————————————————————————
# Fetch v1 proposal (multi-message)
# ————————————————————————————————————————————————————————————————
fetch_prop_data_v1() {
  local raw
  echo "[v1] fetching proposal data..."
  raw=$(curl --connect-timeout 3 -fsS \
    "$GOV_CHAIN_LCD/cosmos/gov/v1/proposals/$PROP_ID")
  echo $raw | jq
  TITLE=$(jq -r '.proposal.title // empty' <<<"$raw")
  SUMMARY=$(jq -r '.proposal.summary // empty' <<<"$raw")
  mapfile -t SUBJECT_IDS < <(jq -r '.proposal.messages[] | .subject_client_id' <<<"$raw")
  mapfile -t SUBSTITUTE_IDS < <(jq -r '.proposal.messages[] | .substitute_client_id' <<<"$raw")
}

# ————————————————————————————————————————————————————————————————
# Fetch client states + host-chain next_validators_hash
# ————————————————————————————————————————————————————————————————
fetch_client_states() {
  # subject client
  echo "  → host client state for $SUBJ_CLIENT_ID"
  SUBJ_CLIENT_HEIGHT=$(
    curl -s --connect-timeout 3 \
      "$GOV_CHAIN_LCD/ibc/core/client/v1/client_states/$SUBJ_CLIENT_ID" \
    | jq -r '.client_state.latest_height.revision_height'
  )
  SUBJ_CLIENT_REVNUM=$(
    curl -s --connect-timeout 3 \
      "$GOV_CHAIN_LCD/ibc/core/client/v1/client_states/$SUBJ_CLIENT_ID" \
    | jq -r '.client_state.latest_height.revision_number'
  )
  SUBJ_CLIENT_VALSET_NEXTHASH=$(
    curl -s --connect-timeout 3 \
      "$GOV_CHAIN_LCD/ibc/core/client/v1/consensus_states/$SUBJ_CLIENT_ID/revision/$SUBJ_CLIENT_REVNUM/height/$SUBJ_CLIENT_HEIGHT" \
    | jq -r '.consensus_state.next_validators_hash'
  )

  # substitute client
  echo "  → host client state for $SUBS_CLIENT_ID"
  SUBS_CLIENT_HEIGHT=$(
    curl -s --connect-timeout 3 \
      "$GOV_CHAIN_LCD/ibc/core/client/v1/client_states/$SUBS_CLIENT_ID" \
    | jq -r '.client_state.latest_height.revision_height'
  )
  SUBS_CLIENT_REVNUM=$(
    curl -s --connect-timeout 3 \
      "$GOV_CHAIN_LCD/ibc/core/client/v1/client_states/$SUBS_CLIENT_ID" \
    | jq -r '.client_state.latest_height.revision_number'
  )
  SUBS_CLIENT_VALSET_NEXTHASH=$(
    curl -s --connect-timeout 3 \
      "$GOV_CHAIN_LCD/ibc/core/client/v1/consensus_states/$SUBS_CLIENT_ID/revision/$SUBS_CLIENT_REVNUM/height/$SUBS_CLIENT_HEIGHT" \
    | jq -r '.consensus_state.next_validators_hash'
  )
}

# ————————————————————————————————————————————————————————————————
# Fetch reference-chain next_validators_hash
# ————————————————————————————————————————————————————————————————
fetch_valsets() {
  # using MSG_REF_RPC
  echo "  → reference header for height $SUBJ_CLIENT_HEIGHT"
  REF_SUBJ_CLIENT_VALSET_NEXTHASH=$(
    curl -s --connect-timeout 3 \
      "$MSG_REF_RPC/block?height=$SUBJ_CLIENT_HEIGHT" \
    | jq -r '.result.block.header.next_validators_hash'
  )

  echo "  → reference header for height $SUBS_CLIENT_HEIGHT"
  REF_SUBS_CLIENT_VALSET_NEXTHASH=$(
    curl -s --connect-timeout 3 \
      "$MSG_REF_RPC/block?height=$SUBS_CLIENT_HEIGHT" \
    | jq -r '.result.block.header.next_validators_hash'
  )
}

# ————————————————————————————————————————————————————————————————
# Print & compare
# ————————————————————————————————————————————————————————————————
print_and_validate() {
  echo
  echo "----------------------------------------"
  echo "Proposal title: $TITLE"
  echo "Message #$((idx+1)): subject=$SUBJ_CLIENT_ID substitute=$SUBS_CLIENT_ID"
  echo "  host:      $SUBJ_CLIENT_VALSET_NEXTHASH"
  echo "  reference: $REF_SUBJ_CLIENT_VALSET_NEXTHASH"
  echo "  host:      $SUBS_CLIENT_VALSET_NEXTHASH"
  echo "  reference: $REF_SUBS_CLIENT_VALSET_NEXTHASH"
  echo "----------------------------------------"

  if [[ "$SUBJ_CLIENT_VALSET_NEXTHASH" == "$REF_SUBJ_CLIENT_VALSET_NEXTHASH" ]]; then
    echo -e "${COL_GREEN}✅ subject client valid${COL_NC}"
  else
    echo -e "${COL_RED}❌ subject client MISMATCH${COL_NC}"
  fi

  if [[ "$SUBS_CLIENT_VALSET_NEXTHASH" == "$REF_SUBS_CLIENT_VALSET_NEXTHASH" ]]; then
    echo -e "${COL_GREEN}✅ substitute client valid${COL_NC}"
  else
    echo -e "${COL_RED}❌ substitute client MISMATCH${COL_NC}"
  fi
  echo
}

# ————————————————————————————————————————————————————————————————
# Main
# ————————————————————————————————————————————————————————————————
main() {
  check_gov_lcd

  if $V1_MODE; then
    fetch_prop_data_v1
  else
    fetch_prop_data
  fi

  for idx in "${!SUBJECT_IDS[@]}"; do
    SUBJ_CLIENT_ID=${SUBJECT_IDS[$idx]}
    SUBS_CLIENT_ID=${SUBSTITUTE_IDS[$idx]}

    echo
    echo Title: $TITLE
    echo Summary: $SUMMARY
    echo
    echo "=== Message #$((idx+1)) ==="
    echo " subject_client_id = $SUBJ_CLIENT_ID"
    echo " substitute_client_id = $SUBS_CLIENT_ID"
    echo

    read -rp "Enter REFERENCE_CHAIN_RPC for this message: " MSG_REF_RPC
    check_ref_rpc "$MSG_REF_RPC"

    fetch_client_states
    fetch_valsets
    print_and_validate
  done
}

main "$@"
