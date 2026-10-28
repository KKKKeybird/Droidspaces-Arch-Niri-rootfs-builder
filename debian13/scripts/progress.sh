#!/usr/bin/env bash
# Stage progress + recurring heartbeat for long-running tasks in GitHub Actions.
# Stage bars represent completed workflow stages; compiler heartbeats are
# intentionally indeterminate, because Zig/Cargo do not expose percent done.
set -Eeuo pipefail

bar() {
  local count="$1" total="$2" width=18 filled i out=""
  filled=$((count*width/total))
  for ((i=0; i<width; i++)); do
    if (( i < filled )); then out+="█"; else out+="░"; fi
  done
  printf '%s' "$out"
}

if [[ "${1:-}" == stage ]]; then
  idx="$2"; total="$3"; title="$4"
  if (( idx < 0 || total <= 0 || idx > total )); then exit 2; fi
  printf '[STAGE] [%s] %s/%s completed: %s\n' "$(bar "$idx" "$total")" "$idx" "$total" "$title"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '- [%s/%s] %s ✅\n' "$idx" "$total" "$title" >> "$GITHUB_STEP_SUMMARY"
  fi
  exit 0
fi

if [[ "${1:-}" != run || $# -lt 4 ]]; then
  echo "Usage: $0 stage N TOTAL LABEL | run LABEL INTERVAL_SECONDS COMMAND..." >&2
  exit 2
fi
label="$2"; interval="$3"; shift 3
[[ "$interval" =~ ^[0-9]+$ ]] && (( interval >= 5 )) || exit 2
started=$SECONDS
echo "[HEARTBEAT] Starting $label: $*"
"$@" &
child=$!
trap 'kill "$child" 2>/dev/null || true' INT TERM
while kill -0 "$child" 2>/dev/null; do
  sleep "$interval" &
  wait $! || true
  if kill -0 "$child" 2>/dev/null; then
    elapsed=$((SECONDS-started))
    position=$(((elapsed/interval)%16))
    pulse=""
    for ((i=0; i<16; i++)); do
      if (( i == position )); then pulse+="█"; else pulse+="░"; fi
    done
    printf '[HEARTBEAT] [%s] %s running | %dm%02ds elapsed | no estimated %%\n' \
       "$pulse" "$label" "$((elapsed/60))" "$((elapsed%60))"
  fi
done
set +e
wait "$child"
result=$?
set -e
elapsed=$((SECONDS-started))
if (( result == 0 )); then
  echo "[HEARTBEAT] Completed $label in $((elapsed/60))m$((elapsed%60))s"
else
  echo "::error::Failed $label (exit=$result) after $((elapsed/60))m$((elapsed%60))s"
fi
exit "$result"
