#!/usr/bin/env bash
# Audit post-commit + correctifs optionnels (+x) — MCGT
# Usage:
#   bash post_commit_sanity_v1.sh           # audit seul (pas de modifications)
#   APPLY=1 bash post_commit_sanity_v1.sh   # applique les +x manquants sur scripts à shebang
set -Eeuo pipefail
trap 'code=$?; echo; echo "[SAFE] Fin avec code $code — fenêtre conservée."; read -rp "Entrée pour quitter..." _' EXIT

ts="$(date -u +%Y%m%dT%H%M%SZ)"
logdir="/tmp/mcgt_post_commit_${ts}"
mkdir -p "$logdir"

echo "[INFO] Logs: $logdir"
echo "[CHECK] Branche & HEAD"
git branch --show-current | tee "$logdir/branch.txt"
git rev-parse --short HEAD   | tee "$logdir/head.txt"

echo "[CHECK] Invariants pins/req"
req_pin_ok=0
dev_pin_ok=0

if grep -qE '^requests==2\.32\.5$' constraints/security-pins.txt && \
   grep -qE '^jupyterlab==4\.4\.8$' constraints/security-pins.txt; then
  echo "[OK] constraints/security-pins.txt contient les pins attendus"; req_pin_ok=1
else
  echo "[WARN] constraints/security-pins.txt ne contient pas exactement 'requests==2.32.5' et 'jupyterlab==4.4.8'"
fi

if ! grep -qi '^jupyterlab' requirements.txt; then
  echo "[OK] Pas de jupyterlab en runtime (requirements.txt)"; else
  echo "[WARN] jupyterlab trouvé dans requirements.txt"; fi

if grep -qi '^jupyterlab==4\.4\.8' requirements-dev.txt; then
  echo "[OK] jupyterlab==4.4.8 présent en dev"; dev_pin_ok=1
else
  echo "[WARN] jupyterlab==4.4.8 absent de requirements-dev.txt"
fi

echo "[CHECK] Pré-commit (validation+exécution)"
( pre-commit validate-config && pre-commit run --all-files ) || true

echo "[SCAN] pip install -r requirements.txt SANS PIP_CONSTRAINT"
# Liste des fichiers (staged & worktree) contenant une install non contrainte
violations="$(git ls-files -z | xargs -0 grep -nE "pip +install +-r +requirements\.txt" || true)"
echo "$violations" | tee "$logdir/pip_installs_raw.txt" >/dev/null
violations_nc="$(echo "$violations" | grep -v 'PIP_CONSTRAINT' || true)"
if [ -n "${violations_nc:-}" ]; then
  echo "[WARN] Installations pip non contraintes détectées:"
  echo "$violations_nc" | tee "$logdir/pip_installs_missing_constraint.txt"
else
  echo "[OK] Toutes les invocations pip -r requirements.txt sont contraintes"
fi

echo "[CHECK] pip-audit (si installé)"
if command -v pip-audit >/dev/null 2>&1; then
  pip-audit | tee "$logdir/pip_audit_runtime.txt" || true
  pip-audit -r requirements-dev.txt | tee "$logdir/pip_audit_dev.txt" || true
else
  echo "[INFO] pip-audit non installé — skipped"
fi

echo "[SCAN] Shebang mais bit exécutable manquant"
mapfile -t shebang_files < <(git ls-files | \
  xargs -I{} bash -lc 'f="{}"; head -n1 "$f" 2>/dev/null | grep -qE "^#\!/" && echo "$f"' || true)

need_exec=()
for f in "${shebang_files[@]}"; do
  [ -f "$f" ] || continue
  if [ ! -x "$f" ]; then
    need_exec+=("$f")
  fi
done

if ((${#need_exec[@]})); then
  printf "%s\n" "${need_exec[@]}" | tee "$logdir/missing_exec_bit.txt" >/dev/null
  echo "[WARN] ${#need_exec[@]} fichier(s) avec shebang sans +x"
  if [ "${APPLY:-0}" = "1" ]; then
    echo "[FIX] Ajout du bit exécutable (+x) aux scripts détectés"
    printf "%s\0" "${need_exec[@]}" | xargs -0 chmod +x
    echo "[OK] +x appliqué. Pense à: git add -A && git commit -m 'chore: restore +x on shebang scripts'"
  else
    echo "[HINT] Pour corriger: APPLY=1 bash post_commit_sanity_v1.sh"
  fi
else
  echo "[OK] Tous les scripts à shebang sont exécutables"
fi

echo "[SUMMARY]"
echo " - pins fichier: $req_pin_ok ; jlab dev: $dev_pin_ok"
echo " - installs pip non contraintes listées sous $logdir (si présent)"
echo " - scripts non exécutables listés (si présent)"
echo "[DONE] Détails: $logdir"
