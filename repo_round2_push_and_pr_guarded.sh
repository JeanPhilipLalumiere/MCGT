# repo_round2_push_and_pr_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round2_push_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'echo; echo "[GUARD] Fin (exit=$?) — log: $LOG"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD

BR="$(git rev-parse --abbrev-ref HEAD)"
[ "$BR" = "fix/ch09-fig03-parse" ] || echo "[WARN] Branche courante = $BR (attendu: fix/ch09-fig03-parse)"

# 1) Sanity minimal
python -m py_compile zz-scripts/chapter09/run_fig03_safe.py
for f in zz-scripts/chapter10/plot_fig0{1..5}_*.py; do python -m py_compile "$f"; done

# 2) Tag local de bornage si absent
TAG="v0.3.9-round2-local"
if ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  git tag -a "$TAG" -m "Round2 locked (safe-runner ch09/fig03) — ${TS}"
  echo "[OK] Tag local créé: $TAG"
else
  echo "[NOTE] Tag déjà présent: $TAG"
fi

# 3) Push branche + tag
set +e
git push -u origin "$BR"
PUSH_BR=$?
git push origin "$TAG"
PUSH_TAG=$?
set -e
echo "[INFO] push branche=$PUSH_BR, push tag=$PUSH_TAG"

# 4) Ouvrir PR (gh si dispo), sinon afficher la commande
TITLE="Round2 lock + safe-runner ch09/fig03 (ADD 20/20, REVIEW 16/16)"
BODY=$'Verrouille Round2 sans modifier le producteur ch09/fig03.\n- Figures ch10 ok (01–05)\n- Runner sûr ch09/fig03\n- Probe Round2 = 20/20 + 16/16\n- Manifeste csv→csv.gz: safe-only\n\nÉtapes suivantes: patch minimal du main() de ch09/fig03, README-REPRO, CI smoke.'

if command -v gh >/dev/null 2>&1; then
  gh pr create --fill --title "$TITLE" --body "$BODY" --base main --head "$BR" || {
    echo "[WARN] gh pr create a échoué. Commande équivalente:"
    echo "gh pr create --title \"$TITLE\" --body <(printf \"%s\" \"$BODY\") --base main --head \"$BR\""
  }
else
  echo "[NOTE] gh non disponible. Ouvre la PR manuellement ou installe gh."
  echo "Commande suggérée (après installation) :"
  echo "gh pr create --title \"$TITLE\" --body <(printf \"%s\" \"$BODY\") --base main --head \"$BR\""
fi
