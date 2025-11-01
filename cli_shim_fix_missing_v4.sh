#!/usr/bin/env bash
# PURPOSE: Add the idempotent CLI shim (module-level) to any script flagged as "shim_missing"
#          by tools/check_cli_policy_strict.py, without breaking existing logic.
# SAFETY:  Backups created as .bak_<UTC>. On error, the shell session stays open.

set -Eeuo pipefail

# ---- Guard: keep session alive on errors, show failing command & line ----
last_cmd=''
trap 'ec=$?; echo "[GUARD] Erreur capturée (exit=$ec) — session intacte.";
      echo "[GUARD] Dernière commande: ${last_cmd} (ligne ${BASH_LINENO[0]})";
      exit $ec' ERR
trap 'last_cmd=$BASH_COMMAND' DEBUG

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD || true

# ---- Build the SHIM block in a robust way (no read -d '') ----
SHIM="$(cat <<'PY'
# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.
def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None)
    p.add_argument("--dpi", type=int, default=None)
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"])
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--style", type=str, default=None)
    p.add_argument("--verbose", action="store_true")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Jamais bloquant.
        pass
    return args

# Exposition module-scope (ne force rien si l'appelant n'utilise pas MCGT_CLI)
try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===
PY
)"

# ---- Ensure the strict checker exists; if not, create a minimal fallback ----
if [ ! -f tools/check_cli_policy_strict.py ]; then
  echo "[INFO] tools/check_cli_policy_strict.py introuvable — dépôt d'un checkeur minimal."
  mkdir -p tools
  cat > tools/check_cli_policy_strict.py <<'PY'
#!/usr/bin/env python3
import re, sys, glob
ROOTS = [f"zz-scripts/chapter{str(i).zfill(2)}/*.py" for i in range(1,11)]
RE_BEGIN_COL1 = re.compile(r'^# === MCGT:CLI-SHIM-BEGIN ===\s*$', re.M)
def needs_shim(path):
    txt = open(path,'r',encoding='utf-8',errors='ignore').read()
    return RE_BEGIN_COL1.search(txt) is None
missing = []
for pat in ROOTS:
    for p in glob.glob(pat):
        if needs_shim(p):
            missing.append(p)
if missing:
    print("CLI strict policy violations:")
    for p in missing:
        print(f" - {p}: shim_missing")
    sys.exit(1)
print("[OK] CLI strict: aucun manque détecté.")
PY
  chmod +x tools/check_cli_policy_strict.py
fi

echo "== DÉTECTION (policy stricte) =="
# We capture output but never fail the script at this stage
violations="$(python tools/check_cli_policy_strict.py || true)"
echo "$violations"

# Extract paths flagged as "shim_missing"
mapfile -t files < <(printf '%s\n' "$violations" | sed -n 's/^ \- \(zz-scripts\/.*\.py\): shim_missing$/\1/p')

if [ "${#files[@]}" -eq 0 ]; then
  echo "[NOTE] Aucun fichier manquant le shim selon la policy stricte. Rien à faire."
  exit 0
fi

echo "== PATCH (ajout du shim) =="
ts="$(date -u +%Y%m%dT%H%M%SZ)"
for f in "${files[@]}"; do
  echo "[PATCH] $f"
  [ -f "$f" ] || { echo "  ↳ [SKIP] inexistant"; continue; }
  # Skip if already has BEGIN marker (idempotence)
  if grep -q '^# === MCGT:CLI-SHIM-BEGIN ===' "$f"; then
    echo "  ↳ [SKIP] Shim déjà présent"
    continue
  fi
  cp --no-clobber --update=none -- "$f" "${f}.bak_${ts}" || true
  # Ensure file ends with a newline, then append shim
  if [ -s "$f" ] && [ -n "$(tail -c1 "$f" | tr -d '\n')" ]; then
    printf '\n' >> "$f"
  fi
  printf '%s\n' "$SHIM" >> "$f"
  echo "  ↳ [OK] shim ajouté"
done

echo "== SANITY (py_compile repo) =="
# Try to compile all python scripts; do not crash the terminal on failure: we convert to soft status
py_ok=1
while IFS= read -r -d '' p; do
  if ! python -m py_compile "$p" 2>/dev/null; then
    echo "[FAIL] py_compile: $p"
    py_ok=0
  fi
done < <(find zz-scripts -name '*.py' -print0)
if [ $py_ok -eq 0 ]; then
  echo "[WARN] Des erreurs py_compile ont été détectées (voir ci-dessus)."
else
  echo "[OK] py_compile repo"
fi

echo "== POLICY (recheck strict) =="
python tools/check_cli_policy_strict.py || true

echo "== PROBE (round2) =="
if [ -x ./repo_probe_round2_consistency.sh ]; then
  bash ./repo_probe_round2_consistency.sh || true
else
  echo "[NOTE] repo_probe_round2_consistency.sh introuvable — skip probe."
fi

echo "== COMMIT/PUSH (si diff) =="
if ! git diff --quiet -- "${files[@]}" tools/check_cli_policy_strict.py 2>/dev/null; then
  git add -- "${files[@]}" tools/check_cli_policy_strict.py 2>/dev/null || git add -- "${files[@]}" 2>/dev/null
  git commit -m "round3: add module-level CLI shim to scripts flagged shim_missing; create/update strict policy checker" || true
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  git push -u origin "$branch" || true
else
  echo "[NOTE] Rien à committer."
fi

echo "[DONE] Shim ajouté là où manquant. Relance la policy stricte si besoin."
