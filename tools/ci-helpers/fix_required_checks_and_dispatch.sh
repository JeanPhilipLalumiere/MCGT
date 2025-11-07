#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

PR_NUM="${PR_NUM:-26}"   # tu peux override: PR_NUM=26 bash fix_required_checks_and_dispatch.sh
BR_PR="$(gh pr view "$PR_NUM" --json headRefName -q .headRefName)"
HEAD_SHA="$(gh pr view "$PR_NUM" --json headRefOid -q .headRefOid)"

echo "[INFO] PR #$PR_NUM | Branche: $BR_PR | HEAD: $HEAD_SHA"

# ── 1) S'assure que pypi-build.yml a bien: on: [push, pull_request, workflow_dispatch]
YML=".github/workflows/pypi-build.yml"
if [[ ! -f "$YML" ]]; then
  echo "[ABORT] Fichier manquant: $YML"; read -r -p $'ENTER pour fermer...\n' _ </dev/tty || true; exit 2
fi

# Patch minimal idempotent : ajoute les triggers si absents
add_trigger() {
  local key="$1"
  if ! rg -n "^[[:space:]]*$key:" "$YML" >/dev/null 2>&1 \
     && ! rg -n "^[[:space:]]*on:[[:space:]]*(.*$key.*)" "$YML" >/dev/null 2>&1; then
    echo "[PATCH] Ajoute trigger: $key"
    # Si 'on:' existe déjà en forme bloc, on insère la clé ; sinon, on reconstruit une ligne compacte.
    if rg -n "^[[:space:]]*on:[[:space:]]*$" "$YML" >/dev/null 2>&1; then
      # ajoute en dessous de 'on:'
      awk '
        { print }
        /^[[:space:]]*on:[[:space:]]*$/ && !seen { print "  '"$key"': {}"; seen=1 }
      ' "$YML" > _tmp.yml && mv _tmp.yml "$YML"
    elif rg -n "^[[:space:]]*on:[[:space:]]*\[" "$YML" >/dev/null 2>&1; then
      # forme liste inline: on: [push, pull_request]
      sed -E -e "s/^( *on: *\[)([^\]]*)(\].*)$/\1\2, $key\3/" -i "$YML" || true
      # dédoublonne au besoin
      perl -0777 -pe 's/(on:\s*\[)([^\]]+)\]/"$1".join(", ", do { my %h; grep { !$h{$_}++ } map { s/\s+//gr } split(/\s*,\s*/, $2) })."]"/e' -i "$YML" || true
    else
      # on: absent ou forme simple → réécrit proprement
      awk '
        NR==1{print "on: [push, pull_request, workflow_dispatch]"} {print}
      ' "$YML" > _tmp.yml && mv _tmp.yml "$YML"
    fi
  else
    echo "[OK] Trigger présent: $key"
  fi
}

add_trigger "push"
add_trigger "pull_request"
add_trigger "workflow_dispatch"

# Petite étape “sanity echo” (si absente) après setup-python
if ! rg -n 'Sanity echo' "$YML" >/dev/null 2>&1; then
  echo "[PATCH] Ajoute étape 'Sanity echo' dans le job build"
  awk '
    1
    /actions\/setup-python@v5/ && !ins {
      print; print "      - name: Sanity echo"; print "        run: python -V && echo \"pypi-build alive\""; ins=1; next
    }
  ' "$YML" > _tmp.yml && mv _tmp.yml "$YML"
else
  echo "[OK] Étape Sanity déjà présente"
fi

# ── 2) Commit/push du patch sur la branche de la PR
git switch "$BR_PR" >/dev/null 2>&1 || git checkout -b "$BR_PR" "origin/$BR_PR"
git add "$YML"
git commit -m "ci(pypi-build): ensure on:[push,pull_request,workflow_dispatch] + sanity echo" || true
git push -u origin "$BR_PR"

# ── 3) Nouveau HEAD “vide” pour attacher proprement les runs
git commit --allow-empty -m "ci: attach required checks to PR head"
git push

HEAD_SHA="$(gh pr view "$PR_NUM" --json headRefOid -q .headRefOid)"
echo "[INFO] Nouveau HEAD: $HEAD_SHA"

# ── 4) Dispatch explicite sur CE HEAD
echo "[DISPATCH] pypi-build & secret-scan"
gh workflow run .github/workflows/pypi-build.yml  --ref "$BR_PR" || true
gh workflow run .github/workflows/secret-scan.yml --ref "$BR_PR" || true

# ── 5) Boucle d’attente raisonnable (≤ 20 x 15s) jusqu’à ce que build & gitleaks = success
echo "[WAIT] Attente des 2 checks requis (build & gitleaks)…"
ok=0
for i in $(seq 1 20); do
  sleep 15
  RES="$(gh api repos/:owner/:repo/commits/$HEAD_SHA/check-runs)"
  build_ok="$(echo "$RES" | jq -r '[.check_runs[]|select(.app.name=="GitHub Actions" and .name=="build")|.conclusion] | any(.=="success")')"
  leak_ok="$( echo "$RES" | jq -r '[.check_runs[]|select(.app.name=="GitHub Actions" and .name=="gitleaks")|.conclusion] | any(.=="success")')"
  echo "  - build=$build_ok ; gitleaks=$leak_ok"
  if [[ "$build_ok" == "true" && "$leak_ok" == "true" ]]; then ok=1; break; fi
done

if [[ "$ok" != "1" ]]; then
  echo "[WARN] Les 2 checks ne sont pas tous verts. Tu peux relancer la vérification:"
  echo "  gh pr checks $PR_NUM"
  read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true
  exit 0
fi

# ── 6) Merge
echo "[MERGE] Tentative de merge PR #$PR_NUM"
if gh pr merge "$PR_NUM" --rebase; then
  echo "[OK] PR mergée."
else
  echo "[INFO] Merge bloqué par la review requise."
  echo "Options:"
  echo "  A) Obtenir un APPROVE d’un compte avec write"
  echo "  B) (temp) mettre required_approving_review_count=0 puis restaurer à 1 après merge"
fi

read -r -p $'Fin d’exécution. Appuie sur ENTER pour fermer cette fenêtre…\n' _ </dev/tty || true
