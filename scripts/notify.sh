#!/usr/bin/env bash
# Posts notifications to ntfy. The topic comes from the NTFY_TOPIC repo secret.
# push event: sends every outbox/*.json file added by the push.
# workflow_dispatch: sends one message built from the inputs.
set -euo pipefail

if [ -z "${NTFY_TOPIC:-}" ]; then
  echo "NTFY_TOPIC secret is not set (repo Settings > Secrets and variables > Actions)." >&2
  exit 1
fi

send() { # reads one outbox-style JSON object on stdin
  jq -c --arg topic "$NTFY_TOPIC" '
    {topic: $topic,
     title: (.title // "Amex transfer bonus"),
     message: (.message // "(no text)"),
     tags: ["credit_card"]}
    + (if (.click // "") != "" then {click: .click} else {} end)' \
  | curl -fsS --retry 3 --max-time 30 -H "Content-Type: application/json" \
      --data-binary @- https://ntfy.sh/ > /dev/null
}

if [ "${EVENT_NAME:-}" = "workflow_dispatch" ]; then
  jq -n --arg t "${IN_TITLE:-}" --arg m "${IN_MESSAGE:-}" '{title: $t, message: $m}' | send
  echo "Sent 1 manual notification."
  exit 0
fi

base="${BEFORE_SHA:-}"
if [ -z "$base" ] || ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
  base="HEAD~1"
fi

count=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if ! jq -e 'type == "object"' "$f" > /dev/null 2>&1; then
    echo "Skipping $f: not a JSON object." >&2
    continue
  fi
  send < "$f"
  echo "Sent $f"
  count=$((count + 1))
done < <(git diff --name-only --diff-filter=A "$base" HEAD -- 'outbox/*.json')
echo "Sent $count notification(s)."
