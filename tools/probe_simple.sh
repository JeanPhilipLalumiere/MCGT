#!/usr/bin/env bash
set -Eeuo pipefail
pkg="${1:?usage: $0 <package> <version> [timeout_sec] [interval_sec]}"
ver="${2:?usage: $0 <package> <version> [timeout_sec] [interval_sec]}"
timeout="${3:-900}"
interval="${4:-5}"
deadline=$(( $(date +%s) + timeout ))
while :; do
  if curl -fsS -H 'Cache-Control: no-cache' --max-time 5 \
       "https://pypi.org/simple/${pkg}/?ts=$(date +%s)" | grep -q "$ver"
  then
    echo "/simple: OUI — ${pkg}==${ver} visible."
    exit 0
  fi
  [ "$(date +%s)" -ge "$deadline" ] && { echo "Timeout /simple pour ${pkg}==${ver}"; exit 1; }
  echo "/simple: NON — retry dans ${interval}s…"; sleep "$interval"
done
