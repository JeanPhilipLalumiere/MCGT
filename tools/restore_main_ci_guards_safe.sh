# tools/restore_main_ci_guards_safe.sh
#!/usr/bin/env bash
set -u -o pipefail; set +e
info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

git rev-parse --abbrev-ref HEAD | grep -qx "main" || { warn "Pas sur main — j’arrête."; exit 0; }

# 1) pip-audit: re-bloquant sur push (retire les continuations permissives)
if [ -f .github/workflows/pip-audit.yml ]; then
  cp .github/workflows/pip-audit.yml .github/workflows/pip-audit.yml.bak || true
  sed -i -E 's/continue-on-error:\s*\$\{\{\s*github\.event_name\s*==\s*'\''pull_request'\''\s*\}\}/continue-on-error: false/g' .github/workflows/pip-audit.yml
  sed -i -E 's/continue-on-error:\s*true/continue-on-error: false/g' .github/workflows/pip-audit.yml
  ok "pip-audit → bloquant en push"
fi

# 2) Retire les adoucisseurs liés à rewrite/* (commenter les if de skip)
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$f" ] || continue
  sed -i -E 's@^(\s*)if:\s*.*rewrite/.*@\1# removed temporary soften (rewrite/*)@' "$f"
done
ok "Garde-fous de base restaurés"

# 3) Commit/push si diff
if ! git diff --quiet -- .github/workflows; then
  git add .github/workflows
  git commit -m "ci(main): restore strict guards (pip-audit blocking, remove rewrite/* softeners)"
  git push || warn "push non effectué (vérifie tes droits réseau)"
  ok "CI stricte rétablie (commit créé)"
else
  ok "Aucun changement CI à committer"
fi
