#!/usr/bin/env bash
# nudge_ci_and_merge_pr35.sh — réveille la CI sur PR #35 et merge normalement
set -euo pipefail
PR="${1:-35}"

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
echo "[INFO] PR #$PR → $(gh pr view "$PR" --json url -q .url)"
HEAD_REF="$(gh pr view "$PR" --json headRefName -q .headRefName)"

# 1) Rebase ou merge main → branche PR (évite "not up to date with base")
git fetch origin
gh pr checkout "$PR"
git rebase origin/main || { git rebase --abort || true; git merge --no-ff origin/main || true; }
git push -u origin HEAD --force-with-lease || true

# 2) "Coup de coude" CI (synchronize) + dispatch best-effort
git commit --allow-empty -m "chore(ci): nudge CI for PR #$PR" || true
git push || true
gh workflow run pypi-build.yml  --ref "refs/pull/${PR}/head" >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref "refs/pull/${PR}/head" >/dev/null 2>&1 || true

# 3) Poll ≤ 240 s pour les 2 contexts requis
echo "[WAIT] Poll ≤ 240s jusqu'à SUCCESS (pypi-build/build & secret-scan/gitleaks)…"
ok="KO"
for i in {1..24}; do
  sleep 10
  rollup="$(gh pr view "$PR" --json statusCheckRollup | jq -r '.statusCheckRollup[]? | [.name, .conclusion] | @tsv')"
  echo "[POLL $i]"; printf "%s\n" "$rollup" | sed 's/\t/=/'
  grep -q "^pypi-build/build\tSUCCESS$"   <<<"$rollup" && \
  grep -q "^secret-scan/gitleaks\tSUCCESS$" <<<"$rollup" && { ok="OK"; break; }
done

if [ "$ok" != "OK" ]; then
  echo "[WARN] Checks pas tous verts (≤240s). Arrêt propre (pas de fast-track ici)."
  read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
  exit 1
fi

# 4) Merge normal (respect protections)
gh pr merge "$PR" --squash --delete-branch

# 5) Sanity courte sur main
git switch main && git pull --ff-only
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..12}; do
  sleep 5
  okm=$(gh run list --branch main --limit 10 | awk '/pypi-build|secret-scan/ && /completed/ && /success/ {c++} END{print (c>=2)?"OK":"KO"}')
  echo "[SANITY $i] $okm"; [ "$okm" = "OK" ] && break
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
