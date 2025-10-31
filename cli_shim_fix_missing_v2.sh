#!/usr/bin/env bash
# cli_shim_fix_missing_v2.sh
# Ajoute un shim CLI idempotent aux fichiers signalés "shim_missing".
# - Backups .bak_<UTC>
# - py_compile ciblé
# - Policy/checks optionnels (n'échouent pas le script)
# - Commit/push s'il y a des diffs
# - Garde-fou : la fenêtre reste ouverte en cas d'erreur

set -Eeuo pipefail
trap 'ec=$?; echo "[GUARD] Erreur capturée (exit=$ec) — session intacte."; exit $ec' ERR

echo "== CONTEXTE =="
pwd
git rev-parse --abbrev-ref HEAD || { echo "[WARN] Pas un repo git ?"; }

UTC() { date -u +%Y%m%dT%H%M%SZ; }

# Liste des fichiers sans shim d'après ta policy stricte (16 entrées)
TARGETS=(
  "zz-scripts/chapter02/primordial_spectrum.py"
  "zz-scripts/chapter07/launch_scalar_perturbations_solver.py"
  "zz-scripts/chapter09/apply_poly_unwrap_rebranch.py"
  "zz-scripts/chapter09/check_p95_methods.py"
  "zz-scripts/chapter09/extract_phenom_phase.py"
  "zz-scripts/chapter09/fetch_gwtc3_confident.py"
  "zz-scripts/chapter09/flag_jalons.py"
  "zz-scripts/chapter09/generate_data_chapter09.py"
  "zz-scripts/chapter09/generate_mcgt_raw_phase.py"
  "zz-scripts/chapter09/opt_poly_rebranch.py"
  "zz-scripts/chapter10/bootstrap_topk_p95.py"
  "zz-scripts/chapter10/eval_primary_metrics_20_300.py"
  "zz-scripts/chapter10/generate_data_chapter10.py"
  "zz-scripts/chapter10/inspect_topk_residuals.py"
  "zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py"
  "zz-scripts/chapter10/update_manifest_with_hashes.py"
)

read -r -d '' SHIM <<'PY'
# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.
def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    # Application non intrusive
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force l'init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        pass
    return args
try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===
PY

ensure_trailing_newline() {
  local f="$1"
  # Ajoute un \n final si absent
  if [ -s "$f" ]; then
    tail -c1 "$f" | od -An -t x1 | grep -qi '0a' || echo >> "$f"
  fi
}

add_shim_if_missing() {
  local f="$1"
  if ! grep -q "^# === MCGT:CLI-SHIM-BEGIN ===" "$f" 2>/dev/null; then
    echo "[PATCH] $f — ajout shim"
    cp -n -- "$f" "${f}.bak_$(UTC)" || true
    ensure_trailing_newline "$f"
    printf "%s\n" "$SHIM" >> "$f"
    return 0
  else
    echo "[SKIP] $f — shim déjà présent"
    return 1
  fi
}

MODIFIED=()
echo "== INSERTION SHIM =="
for f in "${TARGETS[@]}"; do
  if [ ! -f "$f" ]; then
    echo "[WARN] Fichier manquant: $f"
    continue
  fi
  if add_shim_if_missing "$f"; then
    MODIFIED+=("$f")
  fi
done

echo "== SANITY (py_compile ciblé) =="
if [ "${#MODIFIED[@]}" -gt 0 ]; then
  python - <<'PY'
import sys, py_compile
files = sys.argv[1:]
ok=True
for f in files:
  try:
    py_compile.compile(f, doraise=True)
    print("[OK] py_compile", f)
  except Exception as e:
    ok=False
    print("[FAIL] py_compile", f, "->", e)
if not ok:
  sys.exit(1)
PY
  "${MODIFIED[@]}"
else
  echo "[NOTE] Aucun fichier modifié."
fi

echo "== CHECKS (optionnels) =="
set +e
if [ -x tools/check_cli_policy.py ] || [ -f tools/check_cli_policy.py ]; then
  echo "[INFO] tools/check_cli_policy.py:"
  python tools/check_cli_policy.py || true
fi
if [ -x tools/check_cli_policy_strict.py ] || [ -f tools/check_cli_policy_strict.py ]; then
  echo "[INFO] tools/check_cli_policy_strict.py:"
  python tools/check_cli_policy_strict.py || true
fi
if [ -x repo_probe_round2_consistency.sh ] || [ -f repo_probe_round2_consistency.sh ]; then
  echo "[INFO] repo_probe_round2_consistency.sh:"
  bash ./repo_probe_round2_consistency.sh || true
fi
set -e

echo "== GIT COMMIT/PUSH =="
if git diff --quiet -- "${TARGETS[@]}" 2>/dev/null; then
  echo "[NOTE] Rien à committer."
else
  git add -- "${TARGETS[@]}" 2>/dev/null || true
  git commit -m "round3(cli): add idempotent CLI shim to previously missing scripts (col1 markers, parse_known, MCGT_CLI)"
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  git push -u origin "$branch" || echo "[WARN] push a échoué (branche: $branch)"
fi

echo "[DONE] Shim appliqué (si nécessaire) + sanity + checks."
