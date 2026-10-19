#!/usr/bin/env bash
# Waits until every Argo CD application is Synced and Healthy (used by CI).
set -uo pipefail

TIMEOUT="${1:-900}"
deadline=$(( $(date +%s) + TIMEOUT ))

while true; do
  status=$(kubectl -n argocd get applications \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.sync.status}{" "}{.status.health.status}{"\n"}{end}')
  echo "---- $(date +%T)"
  echo "$status" | column -t

  total=$(echo "$status" | grep -c . || true)
  ready=$(echo "$status" | awk '$2=="Synced" && $3=="Healthy"' | grep -c . || true)

  if [ "$total" -gt 0 ] && [ "$ready" -eq "$total" ]; then
    echo "All $total applications are Synced and Healthy."
    exit 0
  fi

  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "Timed out after ${TIMEOUT}s; $ready/$total applications ready."
    exit 1
  fi
  sleep 15
done
