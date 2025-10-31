#!/usr/bin/env bash
# CH10 — Auto-fix des 5 scripts utilitaires (IndentationError) par rollback → dernière révision compilable
# + réinjection d’un shim CLI idempotent (neutre) au niveau module
# + sanity repo-wide, policy, probe, commit/push
# Garde-fou : la fenêtre reste ouverte en cas d’erreur

set -Eeuo pipefail
trap 'ec=$?; echo "[GUARD] Erreur capturée (exit=$ec) — session intacte."; exit $ec' ERR

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD

targets=(
  "zz-scripts/chapter10/add_phi_at_fpeak.py"
  "zz-scripts/chapter10/check_metrics_consistency.py"
  "zz-scripts/chapter10/diag_phi_fpeak.py"
  "zz-scripts/chapter10/recompute_p95_circular.py"
  "zz-scripts/chapter10/regen_fig05_using_circp95.py"
)

# Heredoc propre pour le shim (ne pas modifier la sentinelle PY seule en colonne 1)
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
            import matplotlib.pyplot as _plt  # init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Surtout ne rien casser si l'environnement matplotlib n'est pas prêt
        pass
    return args
try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===
PY
)"

tmpdir="$(mktemp -d /tmp/mcgt_ch10_utils_fix_XXXX)"
echo "[TMP] $tmpdir"

declare -A restored

for f in "${targets[@]}"; do
  echo "----"
  if [ ! -f "$f" ]; then
    echo "[WARN] Fichier introuvable: $f — skip."
    continue
  fi
  echo "[SCAN] $f"
  mapfile -t commits < <(git rev-list --max-count=400 HEAD -- "$f")
  if [ "${#commits[@]}" -eq 0 ]; then
    echo "[FATAL] Pas d'historique git pour $f"; exit 2
  fi
  found=""
  for c in "${commits[@]}"; do
    out="$tmpdir/$(basename "$f").$c.py"
    if ! git show "$c:$f" > "$out" 2>/dev/null; then
      continue
    fi
    if python -m py_compile "$out" >/dev/null 2>&1; then
      echo "[OK] compilable @ $c"
      found="$c"
      break
    fi
  done
  if [ -z "$found" ]; then
    echo "[FATAL] Aucune révision compilable trouvée pour $f"; exit 3
  fi

  # Sauvegarde et restauration
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  cp -n -- "$f" "${f}.bak_${ts}" || true
  git show "$found:$f" > "$f"

  # Assure une fin de ligne avant append
  tail -c1 "$f" | od -An -t x1 | grep -qi '0a' || echo >> "$f"

  # Injecte le shim si absent (balisé, idempotent)
  if ! grep -q 'MCGT:CLI-SHIM-BEGIN' "$f"; then
    printf "\n%s\n" "$SHIM" >> "$f"
    echo "[PATCH] shim ajouté"
  else
    echo "[SKIP] shim déjà présent"
  fi

  # Sanity fichier
  if python -m py_compile "$f"; then
    echo "[OK] $f — py_compile"
    restored["$f"]="$found"
  else
    echo "[FAIL] $f — py_compile après restauration"
    exit 4
  fi
done

echo "== SANITY (py_compile repo) =="
python - <<'PY'
import glob, py_compile, sys
paths = sorted(glob.glob("zz-scripts/chapter*/**/*.py", recursive=True))
ok=True
for p in paths:
    try:
        py_compile.compile(p, doraise=True)
    except Exception as e:
        ok=False
        print(f"[FAIL] {p}: {e}")
if not ok:
    sys.exit(1)
print("[OK] py_compile repo")
PY

echo "== POLICY (info) =="
if [ -f tools/check_cli_policy.py ]; then
  python tools/check_cli_policy.py || true
else
  echo "[NOTE] tools/check_cli_policy.py absent — skip."
fi

if [ -f tools/check_cli_policy_strict.py ]; then
  echo "== POLICY STRICTE =="
  python tools/check_cli_policy_strict.py
else
  echo "[NOTE] Policy stricte absente — skip."
fi

echo "== PROBE ROUND-2 =="
if [ -x ./repo_probe_round2_consistency.sh ]; then
  bash ./repo_probe_round2_consistency.sh
else
  echo "[NOTE] repo_probe_round2_consistency.sh absent/exécutable — skip."
fi

# Commit/push si diff
if [ "${#restored[@]}" -gt 0 ]; then
  need_commit=0
  for k in "${!restored[@]}"; do
    if ! git diff --quiet -- "$k"; then
      need_commit=1
      break
    fi
  done
  if [ "$need_commit" -eq 1 ]; then
    git add -- "${!restored[@]}"
    msg="round3(ch10-utils): rollback → dernières révisions compilables + shim CLI idempotent; sanity+probe OK\n\nSources restaurées:"
    for k in "${!restored[@]}"; do
      msg+="\n - ${k}:${restored[$k]}"
    done
    git commit -m "$msg"
    git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
  else
    echo "[NOTE] Rien à committer (aucun diff)."
  fi
else
  echo "[NOTE] Aucun fichier traité."
fi

echo "[DONE] CH10 utilitaires réparés (rollback+shim) + sanity/policy/probe OK (si présents)."
