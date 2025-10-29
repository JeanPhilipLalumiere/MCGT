#!/usr/bin/env bash
# restore_bak_guarded.sh — restaure *.bak → cible sans .bak (sans overwrite), sinon place en attic/_bak_conflicts/<TS>/
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
LAST_AUD="$(ls -1d _tmp/bak_audit_* 2>/dev/null | sort -r | head -n1 || true)"
MAP="${LAST_AUD:+$LAST_AUD/mapping.tsv}"

if [[ -z "${LAST_AUD:-}" || ! -s "${MAP:-/dev/null}" ]]; then
  echo "[ERR] Aucun audit trouvé. Lance d’abord: bash audit_bak_and_types.sh"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
  exit 2
fi

TS="$(basename "$LAST_AUD" | sed 's/.*_//')"
BR="chore/restore-bak-${TS}"
LOG="_logs/restore_bak_${TS}.log"
mkdir -p _logs "attic/_bak_conflicts/${TS}"

echo "[INFO] Using mapping: $MAP" | tee "$LOG"
echo "[INFO] Creating branch: $BR" | tee -a "$LOG"
git switch -c "$BR" >/dev/null

restored=0
conflicted=0
while IFS=$'\t' read -r kind bak target exists; do
  [[ -z "${bak:-}" ]] && continue
  if [[ "$exists" == "no" ]]; then
    # safe to restore
    mkdir -p "$(dirname "$target")"
    if git mv -k "$bak" "$target" 2>>"$LOG"; then
      echo "[RESTORE] $bak -> $target" | tee -a "$LOG"
      restored=$((restored+1))
    else
      # fallback to mv then git add/rm
      echo "[WARN] git mv failed, fallback mv+git add" | tee -a "$LOG"
      mv "$bak" "$target"
      git add -A "$target"
      git rm -f --cached "$bak" 2>/dev/null || true
      restored=$((restored+1))
    fi
  else
    # conflict: keep .bak but move to attic to avoid clutter
    dest="attic/_bak_conflicts/${TS}/${bak#./}"
    mkdir -p "$(dirname "$dest")"
    echo "[CONFLICT] target exists, moving $bak -> $dest" | tee -a "$LOG"
    git mv -k "$bak" "$dest" 2>>"$LOG" || { mv "$bak" "$dest"; git add -A "$dest"; git rm -f --cached "$bak" 2>/dev/null || true; }
    conflicted=$((conflicted+1))
  fi
done < "$MAP"

git add -A
git commit -m "cleanup(bak): restore $restored files; move $conflicted conflicts to attic/_bak_conflicts/$TS" >/dev/null || true
git push -u origin HEAD >/dev/null || true
gh pr create --fill >/dev/null || true

echo "[DONE] restored=$restored ; conflicts_to_attic=$conflicted" | tee -a "$LOG"
echo "[NEXT] Ouvre la PR et vérifie. Ensuite relance: bash round2_checkpoint_robuste.sh" | tee -a "$LOG"
read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
