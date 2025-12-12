#!/usr/bin/env bash
# Refresh a single entry in zz-manifests/manifest_master.json to match the
# current working tree content (sha256/size/mtime/git_hash).
#
# Safe-guards:
# - Clear status messages with timestamps
# - Strict mode + controlled traps
# - Preflight checks (deps, files, manifest presence of path)
# - Interactive hold-on-exit when launched from a GUI (double-click), but no hold in CI
#
# Usage: tools/manifest_refresh_entry.sh <path>

set -euo pipefail

# -------- pretty logging --------
ts() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
say() { echo "[$(ts)] $*"; }

# Hold on exit only if we have a TTY and HOLD_ON_EXIT!=0 (defaults to 1)
HOLD_ON_EXIT="${HOLD_ON_EXIT:-1}"
_hold_if_tty() {
  if [[ -t 1 && "${HOLD_ON_EXIT}" != "0" ]]; then
    read -r -p $'[DONE] Press Enter to close… ' </dev/tty || true
  fi
}
trap _hold_if_tty EXIT

# -------- args & constants --------
: "${1:?usage: $0 <path>}"
P="$1"
M='zz-manifests/manifest_master.json'

say "== manifest_refresh_entry: start =="
say "[input] path=${P}"

# -------- preflight --------
need() {
  command -v "$1" >/dev/null 2>&1 || { say "ERROR: missing dependency '$1'"; exit 2; }
}
need jq
need git
need sha256sum
need stat
need date

[[ -f "$P" ]] || { say "ERROR: file not found: $P"; exit 2; }
[[ -f "$M" ]] || { say "ERROR: manifest not found: $M"; exit 2; }

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git ls-files --error-unmatch -- "$P" >/dev/null 2>&1; then
    TRACKED=1
  else
    TRACKED=0
    say "WARN: '$P' is not tracked by git (continuing; will try HEAD:<path> best-effort)."
  fi
else
  say "WARN: not inside a git repo; will refresh sha/size/mtime only."
  TRACKED=0
fi

# Ensure entry exists in manifest
if ! jq -e --arg p "$P" '.files | any(.path == $p)' "$M" >/dev/null; then
  say "ERROR: path '$P' not found in manifest entries"; exit 3;
fi

# -------- collect fresh facts --------
SHA="$(sha256sum "$P" | awk '{print $1}')"
SIZE="$(stat -c%s "$P")"
MTIME="$(date -u -d @"$(stat -c %Y "$P")" +%Y-%m-%dT%H:%M:%SZ)"

if [[ "$TRACKED" == "1" ]]; then
  GHASH="$(git rev-parse "HEAD:$P")"
else
  if git rev-parse "HEAD:$P" >/dev/null 2>&1; then
    GHASH="$(git rev-parse "HEAD:$P")"
  else
    GHASH=""
  fi
fi

say "[facts] sha256=$SHA size=$SIZE mtime=$MTIME git_hash=${GHASH:-<none>}"

# -------- backup & patch --------
BTS="$(date -u +%Y%m%dT%H%M%SZ)"
say "[backup] -> ${M}.bak.${BTS}"
cp -v -- "$M" "${M}.bak.${BTS}"

say "[patch] updating manifest entry for '$P'"
jq --arg p "$P" \
   --arg sha "$SHA" \
   --argjson size "$SIZE" \
   --arg mt "$MTIME" \
   --arg gh "$GHASH" '
  .files |= map(
    if .path == $p then
      . + {sha256:$sha, size_bytes:$size, mtime_iso:$mt}
      + (if ($gh|length) > 0 then {git_hash:$gh} else {} end)
    else . end
  )
' "$M" > "${M}.tmp"

mv -v -- "${M}.tmp" "$M"

# -------- verify (optional) --------
if [[ -x tools/manifest_fix_git_hash_from_diag.sh ]]; then
  say "[verify] fix_git_hash_from_diag"
  bash tools/manifest_fix_git_hash_from_diag.sh
fi
if [[ -x tools/manifest_seal.sh ]]; then
  say "[verify] seal"
  bash tools/manifest_seal.sh
fi

say "== manifest_refresh_entry: done =="
