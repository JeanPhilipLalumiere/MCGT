#!/usr/bin/env bash
# File: stepB1_audit_divergent_tags.sh
set -euo pipefail

need(){ command -v "$1" >/dev/null || { echo "[ERR] $1 manquant"; exit 2; }; }
need git

echo "[INFO] Fetch origin (sans forcer, sans tags massifs)…"
git fetch origin --prune

echo "[INFO] Audit des tags divergents local vs origin…"
# Construit table locale
tmp_local="$(mktemp)"; tmp_remote="$(mktemp)"; trap 'rm -f "$tmp_local" "$tmp_remote"' EXIT
git for-each-ref --format='%(refname:strip=2) %(objectname)' refs/tags > "$tmp_local"

# Table distante (uniquement tags, ignore refs/…/{} annot)
git ls-remote --tags origin | grep -v '\^{}' | awk '{print $2" "$1}' | sed 's|refs/tags/||' > "$tmp_remote"

echo -e "TAG\tLOCAL\tREMOTE\tSTATUS"
join -a1 -a2 -j1 -o 0,1.2,2.2 <(sort -k1,1 "$tmp_local") <(sort -k1,1 "$tmp_remote") \
| while IFS=$'\t' read -r tag local remote; do
  if [[ -z "${remote:-}" ]]; then
    echo -e "${tag}\t${local}\t-\tLOCAL_ONLY"
  elif [[ -z "${local:-}" ]]; then
    echo -e "${tag}\t-\t${remote}\tREMOTE_ONLY"
  elif [[ "$local" != "$remote" ]]; then
    echo -e "${tag}\t${local}\t${remote}\tDIVERGENT"
  fi
done | sort -k4,4 -k1,1
