#!/usr/bin/env bash
# build-form.sh — POST a JSON payload to Typeform's create-form endpoint.
#
# Usage:
#   build-form.sh <token-file> <payload-file>
#
# Arguments:
#   token-file    Path to a file containing only the bearer token (e.g. ~/.config/typeform/omerta.token)
#   payload-file  Path to the JSON form payload
#
# On success: prints a JSON line with form_id, public_url, edit_url.
# On failure: prints diagnostic info to stderr and exits non-zero.

set -euo pipefail

TOKEN_FILE="${1:?token-file path required}"
PAYLOAD_FILE="${2:?payload-file path required}"

if [[ ! -r "$TOKEN_FILE" ]]; then
  echo "build-form.sh: cannot read token file: $TOKEN_FILE" >&2
  exit 64
fi

if [[ ! -r "$PAYLOAD_FILE" ]]; then
  echo "build-form.sh: cannot read payload file: $PAYLOAD_FILE" >&2
  exit 64
fi

TOKEN=$(tr -d '[:space:]' < "$TOKEN_FILE")
if [[ -z "$TOKEN" ]]; then
  echo "build-form.sh: token file is empty: $TOKEN_FILE" >&2
  exit 64
fi

# Validate payload is JSON before sending
if ! jq -e . < "$PAYLOAD_FILE" >/dev/null; then
  echo "build-form.sh: payload is not valid JSON: $PAYLOAD_FILE" >&2
  exit 65
fi

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

HTTP_CODE=$(curl -sS -o "$RESPONSE_FILE" -w "%{http_code}" \
  -X POST "https://api.typeform.com/forms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data @"$PAYLOAD_FILE")

if [[ "$HTTP_CODE" != "201" && "$HTTP_CODE" != "200" ]]; then
  echo "build-form.sh: Typeform API returned HTTP $HTTP_CODE" >&2
  echo "--- response ---" >&2
  cat "$RESPONSE_FILE" >&2
  echo "" >&2
  exit 1
fi

FORM_ID=$(jq -r '.id' < "$RESPONSE_FILE")
if [[ -z "$FORM_ID" || "$FORM_ID" == "null" ]]; then
  echo "build-form.sh: response did not include an 'id' field" >&2
  cat "$RESPONSE_FILE" >&2
  exit 1
fi

jq -n \
  --arg form_id "$FORM_ID" \
  --arg public_url "https://form.typeform.com/to/$FORM_ID" \
  --arg edit_url "https://admin.typeform.com/form/$FORM_ID/create" \
  '{form_id: $form_id, public_url: $public_url, edit_url: $edit_url}'
