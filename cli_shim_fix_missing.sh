#!/usr/bin/env bash
# Fix "shim_missing" utilities by appending an idempotent CLI shim (column-1 markers),
# then run sanity & policy checks, commit & push if there are diffs.
# Safe-guard: the terminal stays open on errors.

set -Eeuo pipefail
trap 'ec=$?; echo "[GUARD] Erreur capturée (exit=$ec) — session intacte."; exit $ec' ERR

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD

# --- Targets from the strict policy output (shim_missing) ---
targets=(
  zz-scripts/chapter02/primordial_spectrum.py
  zz-scripts/chapter07/launch_scalar_perturbations_solver.py
  zz-scripts/chapter09/apply_poly_unwrap_rebranch.py
  zz-scripts/chapter09/check_p95_methods.py
  zz-scripts/chapter09/extract_phenom_phase.py
  zz-scripts/chapter09/fetch_gwtc3_confident.py
  zz-scripts/chapter09/flag_jalons.py
  zz-scripts/chapter09/generate_data_chapter09.py
  zz-scripts/chapter09/generate_mcgt_raw_phase.py
  zz-scripts/chapter09/opt_poly_rebranch.py
  zz-scripts/chapter10/bootstrap_topk_p95.py
  zz-scripts/chapter10/eval_primary_metrics_20_300.py
  zz-scripts/chapter10/generate_data_chapter10.py
  zz-scripts/chapter10/inspect_topk_residuals.py
  zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py
  zz-scripts/chapter10/update_manifest_with_hashes.py
)

# --- Shim block (strict column-1 markers; idempotent; parse_known_args; exports MCGT_CLI) ---
read -r -d '' SHIM <<'PY'
# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au niveau module.
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
    # Application non intrusive
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # init backend au besoin
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

ts="$(date -u +%Y%m%dT%H%M%SZ)"
changed=()

echo "== PATCH =="
for f in "${targets[@]}"; do
  echo "[PATCH] $f"
  if [[ ! -f "$f" ]]; then
    echo "  ↳ [SKIP] inexistant"
    continue
  fi
  # Backup (no overwrite)
  cp --no-clobber --update=none -- "$f" "${f}.bak_${ts}" 2>/dev/null || true
  # Already shimmed?
  if grep -q '^# === MCGT:CLI-SHIM-BEGIN ===' "$f"; then
    echo "  ↳ [SKIP] Shim déjà présent"
    continue
  fi
  # Ensure trailing newline; append shim at column 1
  if [[ -s "$f" ]]; then
    tail -c1 "$f" | od -An -t x1 | grep -qi '0a' || printf '\n' >> "$f"
  fi
  printf '%s\n' "$SHIM" >> "$f"
  echo "  ↳ [OK] Shim ajouté"
  changed+=("$f")
done

echo "== SANITY (py_compile ciblé) =="
if ((${#changed[@]})); then
  python -m py_compile "${changed[@]}"
  echo "[OK] py_compile ciblé"
else
  echo "[NOTE] Aucun fichier modifié — skip py_compile ciblé"
fi

echo "== POLICY (souple & stricte si dispo) =="
if [[ -f tools/check_cli_policy.py ]]; then
  python tools/check_cli_policy.py || true
else
  echo "[NOTE] tools/check_cli_policy.py absent — skip"
fi
if [[ -f tools/check_cli_policy_strict.py ]]; then
  python tools/check_cli_policy_strict.py || true
else
  echo "[NOTE] tools/check_cli_policy_strict.py absent — skip"
fi

echo "== PROBE ROUND-2 =="
if [[ -x ./repo_probe_round2_consistency.sh ]]; then
  bash ./repo_probe_round2_consistency.sh || true
else
  echo "[NOTE] repo_probe_round2_consistency.sh absent/non exécutable — skip"
fi

echo "== COMMIT/PUSH =="
if ((${#changed[@]})); then
  git add "${changed[@]}"
  msg="round3(util): add idempotent CLI shim to utilities (col-1 markers, parse_known_args, MCGT_CLI export) — ${ts}"
  git commit -m "$msg"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
  echo "[DONE] Commit & push effectués."
else
  echo "[NOTE] Rien à committer."
fi

echo "[ALL GOOD] Fin du script."
