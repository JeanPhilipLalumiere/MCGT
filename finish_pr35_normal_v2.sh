#!/usr/bin/env bash
# finish_pr35_normal_v2.sh — remet la PR à jour, lance les checks, merge si vert
set -euo pipefail
PR="${1:-35}"

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
echo "[INFO] PR #$PR → $(gh pr view "$PR" --json url -q .url)"

# 1) Rebase de la branche de la PR sur main (propre)
HEAD_REF="$(gh pr view "$PR" --json headRefName -q .headRefName)"
git fetch origin
gh pr checkout "$PR"
git rebase origin/main || { echo "[HINT] Rebase conflituel → git rebase --abort ; git merge origin/main"; git merge --no-ff origin/main; }
git push -u origin HEAD --force-with-lease || true

# 2) Checks requis côté PR
gh workflow run pypi-build.yml  --ref "refs/pull/${PR}/head" >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref "refs/pull/${PR}/head" >/dev/null 2>&1 || true

echo "[WAIT] Poll ≤ 240s jusqu'à SUCCESS (pypi-build/build & secret-scan/gitleaks)…"
ok="KO"; for i in {1..24}; do
  sleep 10
  got=$(gh pr view "$PR" --json statusCheckRollup \
        | jq -r '.statusCheckRollup[]? | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks") | .name+"="+(.conclusion//"")' \
        | sort | xargs)
  echo "[POLL $i] $got"
  grep -q "pypi-build/build=SUCCESS"   <<<"$got" && \
  grep -q "secret-scan/gitleaks=SUCCESS" <<<"$got" && { ok="OK"; break; }
done

if [ "$ok" != "OK" ]; then
  echo "[WARN] Checks pas tous verts en ≤240s. Stop propre (pas de fast-track ici)."
  read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
  exit 1
fi

# 3) Merge normal (respecte les protections)
gh pr merge "$PR" --squash --delete-branch || {
  echo "[WARN] Merge refusé (policy/review?). Essaie --auto si tu préfères attendre la review: gh pr merge $PR --squash --auto"
  exit 2
}

# 4) Sanity courte sur main
git switch main && git pull --ff-only
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..12}; do
  sleep 5
  r=$(gh run list --branch main --limit 10 | awk '/pypi-build|secret-scan/ && /completed/ && /success/ {c++} END{print (c>=2)?"OK":"KO"}')
  echo "[SANITY $i] $r"
  [ "$r" = "OK" ] && break
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
