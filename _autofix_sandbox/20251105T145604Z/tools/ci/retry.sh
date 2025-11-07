#!/usr/bin/env bash
# retry <n> <sleep_seconds> -- <commande...>
set -euo pipefail
n=${1:-3}; shift || true
s=${1:-5}; shift || true
[ "${1:-}" = "--" ] && shift || true
i=0
until "$@"; do
  i=$((i+1))
  if [ "$i" -ge "$n" ]; then
    echo "retry: échec après $i tentatives" >&2
    exit 1
  fi
  echo "retry: tentative $i échouée, nouvelle tentative dans ${s}s…" >&2
  sleep "$s"
done
