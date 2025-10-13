#!/usr/bin/env bash
# source POSIX copy helper (safe_cp)
. "$(dirname "$0")/lib_posix_cp.sh" 2>/dev/null || . "/home/jplal/MCGT/tools/lib_posix_cp.sh" 2>/dev/null


# --- POSIX helper: cp_if_missing (remplace "safe_cp "SRC" "DEST"") ---
cp_if_missing() {
  # usage: cp_if_missing SRC DEST
  # ne remplace pas si DEST existe déjà
  if [ ! -e "$2" ]; then
    cp "$1" "$2"
  fi
}

set -euo pipefail

# ====================== DALLIDBSX — one-shot full setup ======================
# D: Diagnose/repair pre-commit YAML
# A: Auto-commit/push when YAML is valid
# L: Install lib PSX
# L: Link lib into tools/step*.sh (inject psx_install)
# I: Install local hooks (ban cp -n, ban PSX banner dup)
# D: (2nd) Double-check YAML & run pre-commit
# B: Replace safe_cp "with" "POSIX" idempotent backup logic
# S: Sanity run pre-commit
# X: Robust PSX pause (window waits for Enter)
# Options par défaut = DALLIDBSX (tout)
# ============================================================================

OPTIONS="${OPTIONS:-DALLIDBSX}"
has() { case "$OPTIONS" in *"$1"*) return 0;; *) return 1;; esac; }

# ----------------------- PSX robuste (pour CE script) -----------------------
: "${WAIT_ON_EXIT:=1}"
_psx_one_shot_pause() {
  rc=$?
  echo
  if [ "$rc" -eq 0 ]; then
    echo "✅ DALLIDBSX — Terminé (exit: $rc)"
  else
    echo "❌ DALLIDBSX — Terminé (exit: $rc)"
  fi
  if [ "${WAIT_ON_EXIT}" = "1" ] && [ -z "${CI:-}" ]; then
    if [ -r /dev/tty ]; then
      printf "PSX — Appuie sur Entrée pour fermer cette fenêtre…" > /dev/tty
      IFS= read -r _ < /dev/tty
      printf "\n" > /dev/tty
    elif [ -t 0 ]; then
      read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
      echo
    else
      echo "PSX — Aucun TTY détecté; la fenêtre restera ouverte (Ctrl+C pour fermer)."
      tail -f /dev/null
    fi
  fi
}
trap '_psx_one_shot_pause' EXIT

# ------------------------------ Contexte repo --------------------------------
cd "$(git rev-parse --show-toplevel)"
mkdir -p tools tools/hooks

stage() { git add -A || true; }

# --------------------------- (L) Installer lib PSX ---------------------------
if has L; then
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  [ -s tools/lib_psx.sh ] && cp -f tools/lib_psx.sh "tools/lib_psx.sh.bak_${ts}" || true
  cat > tools/lib_psx.sh <<'LIB'
# PSX library (robust pause) — source me from your scripts
#   . tools/lib_psx.sh
#   psx_install "Étape X — Description"
psx_install() {
  _psx_label="${1:-Run}"
  : "${WAIT_ON_EXIT:=1}"
  trap 'psx__pause "$_psx_label"' EXIT
}
_psx_prompt() {
  if [ -r /dev/tty ]; then
    printf "PSX — Appuie sur Entrée pour fermer cette fenêtre…" > /dev/tty
    IFS= read -r _ < /dev/tty
    printf "\n" > /dev/tty
  elif [ -t 0 ]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
    echo
  else
    echo "PSX — Aucun TTY détecté; la fenêtre restera ouverte (Ctrl+C pour fermer)."
    tail -f /dev/null
  fi
}
psx__pause() {
  rc=$?
  echo
  if [ "$rc" -eq 0 ]; then
    echo "✅ ${_psx_label:-Run} — OK (exit: $rc)"
  else
    echo "❌ ${_psx_label:-Run} — KO (exit: $rc)"
  fi
  if [ "${WAIT_ON_EXIT}" = "1" ] && [ -z "${CI:-}" ]; then
    _psx_prompt
  fi
  return $rc
}
LIB
  chmod +x tools/lib_psx.sh
  stage
fi

# --------------------- (I) Hooks locaux (scripts shell) ---------------------
if has I; then
  # Interdit 'cp -n' dans tools/*.sh
  cat > tools/hooks/forbid_cp_n.sh <<'H1'
#!/usr/bin/env bash
set -euo pipefail
status=0
mapfile -t targets < <(ls -1 tools/*.sh 2>/dev/null || true)
for f in "${targets[@]}"; do
  [ -f "$f" ] || continue
  if grep -nE '(^|[[:space:];])cp[[:space:]]+-n([[:space:]]|$)' "$f" >/dev/null; then
    echo "E: cp_if_missing détecté dans $f" >&2
    status=1
  fi
done
exit $status
H1
  chmod +x tools/hooks/forbid_cp_n.sh

  # Interdit bannières PSX dupliquées + psx_install multiples
  cat > tools/hooks/forbid_psx_dup.sh <<'H2'
#!/usr/bin/env bash
set -euo pipefail
status=0
mapfile -t targets < <(ls -1 tools/*.sh 2>/dev/null || true)
for f in "${targets[@]}"; do
  [ -f "$f" ] || continue
  if [ "$(grep -c 'PSX ROBUST OVERRIDE' "$f" || true)" -gt 1 ]; then
    status=1
  fi
  if [ "$(grep -c '^[[:space:]]*psx_install[[:space:]]*(' "$f" || true)" -gt 1 ]; then
    echo "E: psx_install multiple dans $f" >&2
    status=1
  fi
done
exit $status
H2
  chmod +x tools/hooks/forbid_psx_dup.sh
  stage
fi

# ----------- (D) Réparer .pre-commit-config.yaml si nécessaire --------------
yaml_ok=0
repair_yaml_if_needed() {
  local cfg=".pre-commit-config.yaml"
  [ -f "$cfg" ] || touch "$cfg"
  if ! pre-commit validate-config >/dev/null 2>&1; then
    local ts; ts="$(date -u +%Y%m%dT%H%M%SZ)"
    cp -f "$cfg" "${cfg}.psx_bak_${ts}" || true
    cat > "$cfg" <<'YAML'
repos:
  - repo: local
    hooks:
      - id: forbid-cp-n-in-tools
        name: forbid cp_if_missing in tools
        entry: tools/hooks/forbid_cp_n.sh
        language: system
        files: ^tools/.*\.sh$
      - id: forbid-psx-dup-banner
        entry: tools/hooks/forbid_psx_dup.sh
        language: system
        files: ^tools/.*\.sh$
YAML
    yaml_ok=1
    stage
  else
    yaml_ok=1
  fi
}
has D && repair_yaml_if_needed

# -- (L #2) Injecter lib PSX dans tools/step*.sh s'il n'y a pas déjà psx_install
if has L; then
  for f in tools/step*.sh; do
    [ -f "$f" ] || continue
    if grep -qE '\. tools/lib_psx\.sh|^[[:space:]]*psx_install[[:space:]]*\(' "$f"; then
      continue
    fi
    tmp="$(mktemp)"
    lbl="$(basename "$f")"
    if head -n1 "$f" | grep -q '^#!'; then
      { head -n1 "$f"; echo ". tools/lib_psx.sh"; echo "psx_install \"$lbl\""; tail -n +2 "$f"; } > "$tmp"
    else
      { echo ". tools/lib_psx.sh"; echo "psx_install \"$lbl\""; cat "$f"; } > "$tmp"
    fi
    mv "$tmp" "$f"
    chmod +x "$f"
    stage
  done
fi

# ------- (B) Remplacer safe_cp "par" "backup" POSIX idempotent (hors ce script) ----
if has B; then
  mapfile -t _targets < <(ls -1 tools/*.sh 2>/dev/null || true)
  # Exclure ce script pour éviter auto-modification
  _filtered=()
  for p in "${_targets[@]}"; do
    [ "$(basename "$p")" = "dallidbsx.sh" ] && continue
    _filtered+=("$p")
  done
  if [ "${#_filtered[@]}" -gt 0 ]; then
    python3 - "${_filtered[@]}" <<'PY'
import sys, re, pathlib
paths=sys.argv[1:]
for path in paths:
    p=pathlib.Path(path)
    if not p.is_file(): 
        continue
    s=p.read_text(encoding='utf-8', errors='ignore')
    out=[]; changed=False
    for line in s.splitlines(True):
        if line.lstrip().startswith('#'):
            out.append(line); continue
        # safe_cp "SRC" "DEST"  -> if [ ! -e DEST ]; then cp SRC DEST; fi  # safe_cp "->" "POSIX"
        def repl(m):
            src, dst = m.group(1), m.group(2)
            return f'if [ ! -e {dst} ]; then cp {src} {dst}; fi  # cp_if_missing -> POSIX'
        newline = re.sub(r'(?<!\S)cp\s+-n\s+(\S+)\s+(\S+)(?!\S)', repl, line)
        if newline != line:
            changed=True
        out.append(newline)
    if changed:
        p.write_text(''.join(out), encoding='utf-8')
        print(f"patched: {p}")
PY
    stage || true
  fi
fi

# ---------------------- (S/D) Valider & exécuter hooks ----------------------
has D && pre-commit validate-config || true
if has S; then
  pre-commit run --all-files || true
fi

# ----------------- (A) Commit/push si YAML valide & diff --------------------
if has A; then
  if [ "$yaml_ok" -eq 1 ]; then
    git add -A || true
    if ! git diff --staged --quiet; then
      git commit -m 'chore(psx): install lib, add local hooks; inject psx; cp_if_missing -> POSIX; pre-commit validated'
      git push
    else
      echo "Aucun changement à committer."
    fi
  else
    echo "YAML invalide — commit/push annulés."
  fi
fi

echo "✅ DALLIDBSX — Done."
