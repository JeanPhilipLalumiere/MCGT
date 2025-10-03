#!/usr/bin/env bash
set -Eeuo pipefail

# Audit des workflows GitHub:
# - BOM / CRLF / TAB
# - Clés top-level indentées (name/run-name/on/concurrency/jobs/permissions)
# - run-name contenant ${{ ... }} non quoté
# - uses: actions/(upload|download)-artifact@... sans "name:" dans le bloc `with:`

has_issues=0

log_issue() {
  printf '%s\n' "$1"
  has_issues=1
}

check_file() {
  local f="$1"
  local flagged=0

  # 1) Encodage / whitespace
  if head -c3 "$f" | LC_ALL=C grep -q $'\xEF\xBB\xBF'; then
    log_issue "[BOM] $f: UTF-8 BOM détecté"
    flagged=1
  fi
  if LC_ALL=C grep -q $'\r$' "$f"; then
    log_issue "[CRLF] $f: fins de ligne CRLF"
    flagged=1
  fi
  if LC_ALL=C grep -q $'\t' "$f"; then
    log_issue "[TABS] $f: tabulations trouvées"
    flagged=1
  fi

  # 2) Clés top-level indentées
  if grep -qE '^[[:space:]]{2}(name:|run-name:|on:|concurrency:|jobs:|permissions:)\b' "$f"; then
    log_issue "[TOPLEVEL-INDENT] $f: clés top-level indentées (name/run-name/on/...)"
    flagged=1
  fi

  # 3) run-name non quoté malgré ${{ ... }}
  if ! awk '
    BEGIN{ bad=0 }
    {
      if (match($0, /^[[:space:]]*run-name:[[:space:]]*(.*)$/, m)) {
        v = m[1]
        sub(/[[:space:]]+#.*$/, "", v)         # supprime commentaire de fin
        sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
        if (v ~ /\{\{/) {
          # OK si entouré entièrement par "..." ou '\''...'\'' (un seul type)
          if (!((v ~ /^"/ && v ~ /"$/) || (v ~ /^'\''/ && v ~ /'\''$/))) bad = 1
        }
      }
    }
    END{ exit(bad ? 1 : 0) }
  ' "$f"; then
    log_issue "[RUN-NAME-QUOTING] $f: run-name avec expressions GitHub non quoté"
    flagged=1
  fi

  # 4) upload/download-artifact sans name: dans with:
  #    (on vérifie dans les ~20 lignes qui suivent)
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    local ln="${hit%%:*}"
    if ! sed -n "$((ln + 1)),$((ln + 20))p" "$f" | grep -qE '^[[:space:]]*name:[[:space:]]*[^[:space:]]'; then
      log_issue "[ARTIFACT-NAME] $f:$ln: actions/*-artifact sans 'name:' dans le bloc 'with:'"
      flagged=1
    fi
  done < <(grep -nE '^[[:space:]]*uses:[[:space:]]*actions/(upload|download)-artifact@' "$f" || true)

  return "$flagged"
}

main() {
  shopt -s nullglob
  local files=()
  if (($#)); then
    files=("$@")
  else
    files=(.github/workflows/*.yml .github/workflows/*.yaml)
  fi

  local any=0
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    any=1
    check_file "$f" || true
  done

  if ((!any)); then
    echo "[OK] Aucun workflow à vérifier."
    exit 0
  fi

  if ((has_issues)); then
    echo "[NOK] Problèmes détectés."
    exit 1
  fi

  echo "[OK] Workflows propres."
}

main "$@"
