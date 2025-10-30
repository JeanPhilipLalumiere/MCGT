#!/usr/bin/env bash
# title_consistency_docs_only.sh — Harmonise le titre dans toute la documentation (pas de code)
set -euo pipefail
TITLE="Le Modèle de la Courbure Gravitationnelle du Temps"

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/title_consistency_${TS}.log"
BR="chore/title-consistency-docs"

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

say "[INFO] Branche de travail: $BR"
git fetch origin >/dev/null 2>&1 || true
git switch -c "$BR" 2>/dev/null || git switch "$BR"

# 1) README.md → titre explicite
if [[ -f README.md ]]; then
  awk -v T="$TITLE" '
    NR==1 && $0 ~ /^#\s*(MCGT|.*Courbure Gravitationnelle.*)$/ { print "# " T " (MCGT)"; next }
    { print }' README.md > _tmp.README.$$ && mv _tmp.README.$$ README.md
fi

# 2) CITATION.cff → title:
if [[ -f CITATION.cff ]]; then
  awk -v T="$TITLE" 'BEGIN{d=0} /^title:/ && d==0{print "title: " T; d=1; next} {print} END{if(d==0)print "title: " T}' \
    CITATION.cff > _tmp.CITATION.$$ && mv _tmp.CITATION.$$ CITATION.cff
fi

# 3) Recherche/Remplacement docs (pas de code) — variantes de l’ancien libellé
FILES=$(git ls-files '*.'{md,rst,tex,cff,yml,yaml,toml,json} ':!:**/site/**' ':!:**/build/**' || true)
if [[ -n "$FILES" ]]; then
  perl -CSDA -Mutf8 -0777 -pe \
    "s/mod[èe]le\\s+de\\s+la\\s+courbure\\s+gravitationnelle\\s+temporelle/$TITLE/ig;" \
    -i $FILES || true
fi

# 4) Commit si diff
if ! git diff --quiet; then
  git add -A
  git commit -m "docs: harmonise le titre « ${TITLE} » dans l’ensemble de la documentation"
  git push -u origin "$BR"
  # Ouvre/MAJ PR
  url="$(gh pr view --json url -q .url 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    gh pr create --title "docs: titre officiel (${TITLE})" --body "Harmonisation documentaire du titre. Aucun impact code." || true
    url="$(gh pr view --json url -q .url 2>/dev/null || true)"
  fi
  say "[PR] $url"

  # 5) Checks PR requis (≤ 4 min)
  gh workflow run pypi-build.yml  --ref "$BR" >/dev/null 2>&1 || true
  gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || true

  end=$(( $(date +%s) + 240 ))
  while (( $(date +%s) < end )); do
    roll="$(gh pr view --json statusCheckRollup 2>/dev/null || echo '{}')"
    echo "$roll" | jq -r '.statusCheckRollup[]|[.name,.status,.conclusion]|@tsv' \
      | sed 's/\t/ | /g' | tee -a "$LOG" || true
    echo "$roll" | jq -e '
      [.statusCheckRollup[]
        | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks")
        | .conclusion] as $c
      | ($c|length==2) and ( ($c|index("SUCCESS")!=null) and ($c|rindex("SUCCESS")!=null) )
    ' >/dev/null 2>&1 && { say "[OK] Deux SUCCESS — prêt à merger."; break; }
    sleep 5
  done

  say "[HINT] Pour fusionner avec garde-fou: bash finish_pr30_with_guard.sh"
else
  say "[OK] Rien à harmoniser de plus (docs déjà conformes)."
fi
