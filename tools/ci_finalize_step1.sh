#!/usr/bin/env bash
set -euo pipefail

echo "==> Préparation"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "==> Accepter les auto-fix déjà appliqués (EOF / whitespace / shfmt)"
git add -A || true

echo "==> Poser le bit exécutable sur tous les fichiers suivis avec shebang"
mapfile -d '' SHEBANGS < <(git ls-files -z | xargs -0 -r grep -IlZ '^#!')
for f in "${SHEBANGS[@]}"; do
  [[ -f "$f" ]] || continue
  chmod +x "$f" || true
  git add --chmod=+x "$f" || true
done

echo "==> Corriger proprement SC2015 dans tools/scan_ci_budgets.sh (if/else + tee)"
if [[ -f tools/scan_ci_budgets.sh ]]; then
  awk '
    $0 ~ /\[ *-n *"\$tm" *\] *&&/ && $0 ~ /\| *tee -a *"\$out" *$/ {
      print "if [ -n \"$tm\" ]; then"; print "  msg=\"$tm\""; print "else";
      print "  msg=\"  (no timeout-minutes found)\""; print "fi";
      print "echo \"$msg\" | tee -a \"$out\""; next }
    $0 ~ /\[ *-n *"\$pv" *\] *&&/ && $0 ~ /\| *tee -a *"\$out" *$/ {
      print "if [ -n \"$pv\" ]; then"; print "  msg=\"$pv\""; print "else";
      print "  msg=\"  (no python-version found)\""; print "fi";
      print "echo \"$msg\" | tee -a \"$out\""; next }
    { print }
  ' tools/scan_ci_budgets.sh >tools/scan_ci_budgets.sh.__tmp && mv tools/scan_ci_budgets.sh.__tmp tools/scan_ci_budgets.sh
  chmod +x tools/scan_ci_budgets.sh || true
  git add --chmod=+x tools/scan_ci_budgets.sh || true
fi

echo "==> Ignorer les logs volatiles (.ci-logs/)"
touch .gitignore
grep -qE '^\Q.ci-logs/\E$' .gitignore || echo '.ci-logs/' >>.gitignore
git add .gitignore
git rm -r --cached .ci-logs 2>/dev/null || true

echo "==> Reformatage shell (shfmt) si disponible"
if command -v shfmt >/dev/null 2>&1; then
  git ls-files '*.sh' | xargs -r shfmt -w || true
fi
git add -A || true

echo "==> pre-commit (autorépétition si auto-fix)"
tries=0
until pre-commit run --all-files; do
  tries=$((tries + 1))
  git add -A || true
  if ((tries >= 2)); then
    echo "❌ pre-commit encore en échec après auto-fix."
    exit 1
  fi
done

echo "==> Commit"
if git diff --cached --quiet; then
  echo "Rien à commit."
else
  git commit -m "chore(ci): exec-bits for shebang files, fix SC2015, ignore .ci-logs"
fi

echo "✅ Terminé."
