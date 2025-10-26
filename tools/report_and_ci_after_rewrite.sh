#!/usr/bin/env bash
# tools/report_and_ci_after_rewrite.sh
# - Poste un commentaire de synthèse dans la PR #19
# - Optionnel : relance les workflows de la PR avec gh (si workflows détectés)
# - Never-fail : n'interrompt pas la session, journalise dans _tmp/

set -u  # pas de -e pour éviter de fermer le shell
mkdir -p _tmp

PR_NUMBER="${1:-19}"
REWRITE_BRANCH="${2:-rewrite/main-20251026T134200}"

echo "[INFO] Cible PR: #${PR_NUMBER} depuis ${REWRITE_BRANCH}"

# Lire compteurs
ADDED=$(wc -l < _tmp/sanity_added_paths.txt 2>/dev/null || echo 0)
REMOVED=$(wc -l < _tmp/sanity_removed_paths.txt 2>/dev/null || echo 0)
CHANGED=$(wc -l < _tmp/sanity_changed_paths.txt 2>/dev/null || echo 0)

WT_MATCH=$(wc -l < _tmp/scan_pypi_worktree.txt 2>/dev/null || echo 0)
HIST_MATCH=$(wc -l < _tmp/scan_pypi_history.txt 2>/dev/null || echo 0)

# Préparer extrait (borne à 20 lignes pour ne pas spammer)
head -n 20 _tmp/sanity_added_paths.txt   > _tmp/_added_head.txt   2>/dev/null || true
head -n 20 _tmp/sanity_removed_paths.txt > _tmp/_removed_head.txt 2>/dev/null || true
head -n 20 _tmp/sanity_changed_paths.txt > _tmp/_changed_head.txt 2>/dev/null || true

COMMENT_FILE="_tmp/pr_comment_summary.md"
{
  echo "## Sanity & Security — résumé automatique"
  echo
  echo "**Comparatif arbre (avant ➜ après)**"
  echo "- Ajouts : ${ADDED}"
  echo "- Suppressions : ${REMOVED}"
  echo "- Modifiés : ${CHANGED}"
  echo
  echo "<details><summary>Exemples (ajouts, 1..20)</summary>"
  echo
  echo '```text'
  cat _tmp/_added_head.txt 2>/dev/null || true
  echo '```'
  echo "</details>"
  echo
  echo "<details><summary>Exemples (suppressions, 1..20)</summary>"
  echo
  echo '```text'
  cat _tmp/_removed_head.txt 2>/dev/null || true
  echo '```'
  echo "</details>"
  echo
  echo "<details><summary>Exemples (modifiés, 1..20)</summary>"
  echo
  echo '```text'
  cat _tmp/_changed_head.txt 2>/dev/null || true
  echo '```'
  echo "</details>"
  echo
  echo "**Scan PyPI tokens**"
  echo "- Worktree : ${WT_MATCH} match(s)"
  echo "- Historique : ${HIST_MATCH} match(s)"
  echo
  echo "_Artefacts complets :_ \`_tmp/sanity_*.txt\`, \`_tmp/scan_pypi_*.txt\`"
} > "${COMMENT_FILE}"

echo "[RUN] gh pr comment #${PR_NUMBER}"
gh pr comment "${PR_NUMBER}" --body-file "${COMMENT_FILE}" || {
  echo "[WARN] gh pr comment a échoué. Vérifie l'auth gh."; :
}

# Optionnel : relancer les workflows liés à la PR
echo "[INFO] Recherche des workflows disponibles…"
gh workflow list > _tmp/workflows_list.txt 2>/dev/null || true

# Heuristique : relancer les workflows marqués "test" ou "ci"
WORKFLOW_CANDIDATES=$(awk 'BEGIN{IGNORECASE=1} /test|ci|build/ {print $1}' _tmp/workflows_list.txt | head -n 3)

if [[ -n "${WORKFLOW_CANDIDATES}" ]]; then
  echo "[INFO] Workflows candidats:"
  echo "${WORKFLOW_CANDIDATES}"
  while read -r wf; do
    [[ -z "$wf" ]] && continue
    echo "[RUN] gh workflow run ${wf} -r ${REWRITE_BRANCH}"
    gh workflow run "${wf}" -r "${REWRITE_BRANCH}" || true
  done <<< "${WORKFLOW_CANDIDATES}"
  echo "[INFO] Relances demandées (si autorisées par le repo)."
else
  echo "[INFO] Aucun workflow candidat détecté (ou gh non autorisé à lister)."
fi

echo
echo "──────── Fini ────────"
echo "• Commentaire posté (si gh ok) : ${COMMENT_FILE}"
echo "• Workflows relancés si détectés."
echo "• Passe sur la PR #${PR_NUMBER} et choisis **Rebase and merge** quand la CI est verte."
