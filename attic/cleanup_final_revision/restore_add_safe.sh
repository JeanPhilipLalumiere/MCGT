#!/usr/bin/env bash
# restore_add_safe.sh
# Usage:
#   ./restore_add_safe.sh [zz-out/error_paths.txt] [--no-verify]
#
# Interactive, robust: retries with -f if add fails due to .gitignore,
# asks confirmation before commit & push, waits for Enter before exit.

set -uo pipefail

OUT="${1:-zz-out/error_paths.txt}"
NO_VERIFY=0
if [ "${2:-}" = "--no-verify" ]; then
  NO_VERIFY=1
fi

GOOD="${GOOD:-9fee905}"

echo "=== restore_add_safe.sh ==="
echo "List file: $OUT"
echo "GOOD commit: $GOOD"
echo "No-verify flag: $NO_VERIFY"
echo

if [ ! -s "$OUT" ]; then
  echo "Fichier $OUT introuvable ou vide. Rien à faire."
  read -r -p "Appuie sur Entrée pour quitter..."
  exit 0
fi

added=0
forced=0
missing=()
fail_add=()

while IFS= read -r raw || [ -n "$raw" ]; do
  line="${raw//$'\r'/}"
  p="${line#"${line%%[![:space:]]*}"}"
  p="${p%"${p##*[![:space:]]}"}"
  [ -z "$p" ] && continue
  case "$p" in
    \#*) continue ;;
  esac

  if [ -f "$p" ]; then
    # try plain add
    if git add -- "$p" 2>/tmp/restore_add_err; then
      echo "added: $p"
      added=$((added+1))
      rm -f /tmp/restore_add_err
      continue
    fi

    if [ -f /tmp/restore_add_err ]; then
      stderr="$(cat /tmp/restore_add_err)"
      rm -f /tmp/restore_add_err
    else
      stderr=""
    fi

    if printf '%s' "$stderr" | grep -qi "ignored"; then
      if git add -f -- "$p" 2>/dev/null; then
        echo "added (forced): $p"
        added=$((added+1)); forced=$((forced+1))
      else
        echo "ERROR adding (forced): $p"
        fail_add+=("$p")
      fi
    else
      if git add -f -- "$p" 2>/dev/null; then
        echo "added (forced fallback): $p"
        added=$((added+1)); forced=$((forced+1))
      else
        echo "ERROR adding: $p"
        fail_add+=("$p")
      fi
    fi
  else
    echo "missing: $p"
    missing+=("$p")
  fi
done < "$OUT"

echo
echo "=== Résumé ==="
echo "Files staged        : $added"
echo " - forced (ignored) : $forced"
echo "Files missing       : ${#missing[@]}"
if [ "${#missing[@]}" -gt 0 ]; then
  printf '%s\n' "${missing[@]}" | sed 's/^/  - /'
fi
echo "Files failed to add : ${#fail_add[@]}"
if [ "${#fail_add[@]}" -gt 0 ]; then
  printf '%s\n' "${fail_add[@]}" | sed 's/^/  - /'
fi
echo

if git diff --cached --quiet; then
  echo "Aucun changement staged (index vide)."
else
  echo "Changements staged (aperçu) :"
  git --no-pager diff --cached --name-status || true
  echo

  read -r -p "Veux-tu committer ces changements maintenant ? [y/N] " ans
  case "${ans,,}" in
    y|yes)
      if [ "$NO_VERIFY" -eq 0 ]; then
        read -r -p "Souhaites-tu ignorer les hooks pre-commit (--no-verify) si ils échouent ? [y/N] " skipans
        if [ "${skipans,,}" = "y" ] || [ "${skipans,,}" = "yes" ]; then
          NO_VERIFY=1
        fi
      fi

      cm="restore: restore ERROR files from ${GOOD}"
      if [ "$NO_VERIFY" -eq 1 ]; then
        if git commit --no-verify -m "$cm"; then
          echo "Commit créé (--no-verify)."
        else
          echo "E: git commit --no-verify a échoué."
          git status --porcelain
          git --no-pager diff --cached || true
        fi
      else
        if git commit -m "$cm"; then
          echo "Commit créé."
        else
          echo "E: git commit a échoué (pré-commit probablement)."
          echo "-> lance : pre-commit run --all-files"
          echo "-> ou : python3 zz-manifests/diag_consistency.py zz-manifests/master.json --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on errors > zz-out/diag_master_report_after_restore.json 2>&1 || true"
        fi
      fi

      read -r -p "Veux-tu pousser la branche actuelle vers origin ? [y/N] " pushans
      case "${pushans,,}" in
        y|yes)
          if git push -u origin HEAD; then
            echo "Push OK."
          else
            echo "E: git push a échoué — vérifie ta connexion / permissions."
          fi
          ;;
        *)
          echo "Push ignoré."
          ;;
      esac
      ;;
    *)
      echo "Commit annulé par l'utilisateur."
      ;;
  esac
fi

echo
echo "Actions recommandées :"
echo "- Inspecte zz-out/diag_master_report_after_restore.json après avoir relancé diag_consistency"
echo "- Si des fichiers .bak manquent, cherche dans l'historique (git rev-list --all -- <path>)"
echo

read -r -p "Script terminé. Appuie sur Entrée pour quitter..." dummy
exit 0
