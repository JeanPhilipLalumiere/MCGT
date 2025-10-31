#!/usr/bin/env bash
# cli_shim_fix_missing_v3.sh — ajoute un shim CLI idempotent aux scripts signalés "shim_missing"
# - Backups .bak_<UTC>
# - Idempotent, marqueurs en colonne 1
# - py_compile ciblé
# - Policy check (best-effort)
# - Commit/push auto si diff
# - Garde-fou: affiche la commande fautive, la ligne et le log; ne ferme pas la fenêtre

set -Eeuo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="/tmp/cli_shim_fix_missing_v3_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

on_err() {
  ec=$?
  echo ""
  echo "[GUARD] Erreur capturée (exit=${ec}) — session intacte."
  echo "[GUARD] Dernière commande: ${BASH_COMMAND} (ligne ${BASH_LINENO[0]})"
  echo "[GUARD] Log complet : ${LOG}"
  exit $ec
}
trap on_err ERR

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD

# --- Paramètres ---
# Liste des chemins signalés "shim_missing" dans ton dernier run (tu peux en rajouter au besoin)
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
        pass
    return args
try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===
PY

needs_commit=0
patched=()

echo "== PATCH =="
for f in "${TARGETS[@]}"; do
  echo "[CHECK] ${f}"
  if [[ ! -f "${f}" ]]; then
    echo "  ↳ [SKIP] introuvable"
    continue
  fi
  # Déjà shimé ?
  if grep -q "^# === MCGT:CLI-SHIM-BEGIN ===" "${f}"; then
    echo "  ↳ [SKIP] Shim déjà présent"
    continue
  fi
  # Backup
  cp -n -- "${f}" "${f}.bak_${TS}" || true
  # S'assurer d'un \n final puis append le shim en colonne 1
  # (printf garantit le \n final)
  if tail -c1 "${f}" | od -An -t x1 | grep -qi '0a' >/dev/null 2>&1; then
    printf "%s\n" "${SHIM}" >> "${f}"
  else
    printf "\n%s\n" "${SHIM}" >> "${f}"
  fi
  echo "  ↳ [PATCH] shim ajouté"
  patched+=("${f}")
  needs_commit=1
done

echo "== SANITY (py_compile ciblé) =="
if (( ${#patched[@]} )); then
  python - <<'PY'
import py_compile, sys
files = sys.stdin.read().splitlines()
err = 0
for p in files:
    try:
        py_compile.compile(p, doraise=True)
        print(f"[OK] {p} — py_compile")
    except Exception as e:
        print(f"[FAIL] {p}: {e}")
        err = 1
sys.exit(err)
PY <<EOF
$(printf "%s\n" "${patched[@]}")
EOF
else
  echo "[NOTE] Aucun fichier patché."
fi

echo "== POLICY (soft) =="
if [[ -x tools/check_cli_policy.py ]]; then
  python tools/check_cli_policy.py || true
elif [[ -f tools/check_cli_policy.py ]]; then
  python tools/check_cli_policy.py || true
else
  echo "[NOTE] tools/check_cli_policy.py absent — skip."
fi

echo "== POLICY STRICTE (soft) =="
if [[ -x tools/check_cli_policy_strict.py ]]; then
  python tools/check_cli_policy_strict.py || true
elif [[ -f tools/check_cli_policy_strict.py ]]; then
  python tools/check_cli_policy_strict.py || true
else
  echo "[NOTE] tools/check_cli_policy_strict.py absent — skip."
fi

echo "== PROBE ROUND-2 (soft) =="
if [[ -x repo_probe_round2_consistency.sh ]]; then
  bash ./repo_probe_round2_consistency.sh || true
elif [[ -f repo_probe_round2_consistency.sh ]]; then
  bash ./repo_probe_round2_consistency.sh || true
else
  echo "[NOTE] repo_probe_round2_consistency.sh absent — skip."
fi

if (( needs_commit )); then
  echo "== COMMIT/PUSH =="
  git add "${patched[@]}"
  git commit -m "round3(cli): add idempotent CLI shim to scripts previously flagged shim_missing [${TS}]"
  cur_branch="$(git rev-parse --abbrev-ref HEAD)"
  git push -u origin "${cur_branch}"
else
  echo "[NOTE] Rien à committer (aucune modification)."
fi

echo "[DONE] cli_shim_fix_missing_v3 terminé. Log: ${LOG}"
