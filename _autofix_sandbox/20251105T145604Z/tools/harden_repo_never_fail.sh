#!/usr/bin/env bash
# tools/harden_repo_never_fail.sh
# Version "never-fail": n'échoue jamais (exit 0), n’interrompt pas la session.

# ────────────────────────────────────────────────────────────────────────────────
# Configuration & logging
# ────────────────────────────────────────────────────────────────────────────────
umask 022
mkdir -p _tmp .git/hooks 2>/dev/null || true
LOGFILE="_tmp/harden_repo_safe.log"

# Journaliser tout (stdout+stderr) vers le log ET la console
exec > >(tee -a "$LOGFILE") 2>&1

cyan()  { printf '\033[1;36m%s\033[0m\n' "$*"; }
blue()  { printf '\033[1;34m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[1;33m%s\033[0m\n' "$*"; }
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }

safe_run() {
  # safe_run "message lisible" -- commande…
  local msg="$1"; shift
  blue "[RUN] $msg"
  if "$@"; then
    cyan "[OK ] $msg"
    return 0
  else
    red  "[ERR] $msg"
    yellow "      -> L’erreur est ignorée (mode never-fail)."
    return 0
  fi
}

finish() {
  echo
  cyan "──────────────── Résumé ────────────────"
  echo " • Journal complet : $LOGFILE"
  echo " • Aucune action destructive par défaut."
  echo " • DO_PURGE=1 pour activer la purge historique (voir plus bas)."
  echo " • Pense à activer côté GitHub : Secret Scanning + Push Protection."
  echo "────────────────────────────────────────"
}
trap finish EXIT

# Motif robuste pour tokens PyPI (place '-' en tête de classe)
PYPI_REGEX='pypi-[-A-Za-z0-9_=]{50,}'

# Variables d’option (non destructif par défaut)
DO_PURGE="${DO_PURGE:-0}"
PURGE_LOGS="${PURGE_LOGS:-0}"
REDACT_PYPI="${REDACT_PYPI:-0}"
ALLOW_FORCE_PUSH="${ALLOW_FORCE_PUSH:-0}"

cyan "MCGT • Harden repo (mode never-fail)"
echo "DO_PURGE=$DO_PURGE  PURGE_LOGS=$PURGE_LOGS  REDACT_PYPI=$REDACT_PYPI  ALLOW_FORCE_PUSH=$ALLOW_FORCE_PUSH"
echo

# ────────────────────────────────────────────────────────────────────────────────
# 1) .gitattributes homogène (LF + binaires)
# ────────────────────────────────────────────────────────────────────────────────
safe_run "Écrire .gitattributes canonique" bash -c "
cat > .gitattributes <<'EOF'
* text=auto eol=lf
*.csv  text eol=lf
*.tsv  text eol=lf
*.json text eol=lf
*.md   text eol=lf
*.yml  text eol=lf
*.yaml text eol=lf
*.py   text eol=lf
# Binaires
*.png  binary
*.jpg  binary
*.jpeg binary
*.gif  binary
*.pdf  binary
*.ipynb binary
EOF
"

safe_run "Commit .gitattributes si modifié" bash -c "
git add .gitattributes && git diff --cached --quiet || git commit -m 'chore(repo): add/refresh .gitattributes (LF + binaries)'
"

# ────────────────────────────────────────────────────────────────────────────────
# 2) Hook pre-commit anti-fuite (tokens PyPI + *.log)
# ────────────────────────────────────────────────────────────────────────────────
safe_run "Installer hook pre-commit anti-fuite" bash -c "
cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
PATTERN='pypi-[-A-Za-z0-9_=]{50,}'

changed=\$(git diff --cached --name-only)
[[ -z \"\$changed\" ]] && exit 0

# 1) Tokens PyPI dans le diff indexé
if git diff --cached -U0 | grep -E \"\$PATTERN\" -nq; then
  echo '[BLOCK] Possible PyPI token detected in staged changes.' >&2
  git diff --cached -U0 | grep -E \"\$PATTERN\" -n || true
  exit 1
fi

# 2) Empêcher l'ajout de *.log
if echo \"\$changed\" | grep -E '\.log$' -q; then
  echo '[BLOCK] .log files should not be committed. Add them to .gitignore.' >&2
  exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
"

# ────────────────────────────────────────────────────────────────────────────────
# 3) Scan historique (lecture seule)
# ────────────────────────────────────────────────────────────────────────────────
safe_run "Scanner l’historique pour tokens PyPI → _tmp/scan_pypi.txt" bash -c "
git rev-list --all | xargs -n1 git grep -n -E '$PYPI_REGEX' -- 2>/dev/null > _tmp/scan_pypi.txt || true
if [[ -s _tmp/scan_pypi.txt ]]; then
  echo '[WARN] Des occurrences possibles ont été trouvées (voir _tmp/scan_pypi.txt).'
else
  echo '[INFO] Aucune occurrence détectée par ce scan simple.'
fi
"

# ────────────────────────────────────────────────────────────────────────────────
# 4) Purge historique (optionnelle, jamais forcée par défaut)
# ────────────────────────────────────────────────────────────────────────────────
blue "Purge historique (safe): DO_PURGE=$DO_PURGE, PURGE_LOGS=$PURGE_LOGS, REDACT_PYPI=$REDACT_PYPI"

if [[ "$DO_PURGE" != "1" ]]; then
  yellow "Purge désactivée (défaut). Pour activer : DO_PURGE=1 [PURGE_LOGS=1] [REDACT_PYPI=1] bash tools/harden_repo_never_fail.sh"
else
  if ! command -v git-filter-repo >/dev/null 2>&1; then
    yellow "git-filter-repo non trouvé. Recommandé : 'pipx install git-filter-repo' ou 'python -m pip install --user git-filter-repo'. Skip purge."
  else
    # On sépare volontairement les passes pour des logs plus clairs
    if [[ "$PURGE_LOGS" == "1" ]]; then
      safe_run "Purge des *.log de l’historique (git-filter-repo)" \
        git filter-repo --path-glob "*.log" --invert-paths --force
    fi

    if [[ "$REDACT_PYPI" == "1" ]]; then
      safe_run "Redaction des tokens PyPI (git-filter-repo --replace-text)" bash -c "
        echo 'regex:$PYPI_REGEX==>REDACTED-PYPI-TOKEN' > _tmp/replace_rules.txt
        git filter-repo --replace-text _tmp/replace_rules.txt --force
      "
    fi

    safe_run "Nettoyage local (reflog/gc)" bash -c "
      git reflog expire --expire=now --all || true
      git gc --prune=now --aggressive || true
    "

    if [[ "$ALLOW_FORCE_PUSH" == "1" ]]; then
      BRANCH=$(git rev-parse --abbrev-ref HEAD || echo main)
      yellow "Push --force demandé (ALLOW_FORCE_PUSH=1) → origin/$BRANCH"
      safe_run "git push --force origin $BRANCH" git push --force origin "$BRANCH"
    else
      blue "Pas de push. Vérifie localement, puis pousse manuellement si tout est OK :"
      echo "    git push --force origin \$(git rev-parse --abbrev-ref HEAD)"
    fi
  fi
fi

# Fin — garantir un exit code 0
exit 0
