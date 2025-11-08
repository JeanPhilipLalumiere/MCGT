#!/usr/bin/env bash
set -Eeuo pipefail
trap 'code=$?; if ((code!=0)); then echo; echo "[ERREUR] Sortie avec code $code"; fi' EXIT

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

# Vérifs basiques
have git || { err "git manquant"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null || { err "Pas dans un dépôt Git."; exit 1; }

WFAUDIT=".github/workflows/pip-audit.yml"
WFQL=".github/workflows/codeql.yml"
CONSTRAINTS="constraints/security-pins.txt"

changed=()

# 1) Fichier de contraintes neutre (prêt à pinner plus tard)
if [[ ! -f "$CONSTRAINTS" ]]; then
  info "Création $CONSTRAINTS (neutre)…"
  mkdir -p "$(dirname "$CONSTRAINTS")"
  cat > "$CONSTRAINTS" <<'TXT'
# constraints/security-pins.txt
# Contrôle doux pour CI (pip-audit, installs). Ajoutez vos pins ici si nécessaire, ex.:
# pip-audit==2.7.*
# certifi==2024.8.30
TXT
  changed+=("$CONSTRAINTS")
else
  info "Déjà présent : $CONSTRAINTS"
fi

# 2) Stabiliser pip-audit.yml (spinner off + PIP_CONSTRAINT sur pip install)
if [[ -f "$WFAUDIT" ]]; then
  touched=false

  # 2a) --progress-spinner off sur les invocations pip-audit manquantes
  if grep -Eq 'pip-audit([[:space:]].*)?--progress-spinner[[:space:]]+off' "$WFAUDIT"; then
    info "pip-audit déjà silencieux (--progress-spinner off)"
  else
    info "Ajout '--progress-spinner off' aux lignes pip-audit…"
    awk '{
      if ($0 ~ /pip-audit/ && $0 !~ /--progress-spinner[[:space:]]+off/) {
        sub(/pip-audit/, "pip-audit --progress-spinner off")
      }
      print
    }' "$WFAUDIT" > "$WFAUDIT.tmp" && mv "$WFAUDIT.tmp" "$WFAUDIT"
    touched=true
  fi

  # 2b) Injecter PIP_CONSTRAINT=… pour les "pip install"
  if grep -Eq 'PIP_CONSTRAINT=constraints/security-pins\.txt[[:space:]]+pip install' "$WFAUDIT"; then
    info "PIP_CONSTRAINT déjà injecté dans $WFAUDIT"
  else
    if grep -Eq 'pip install ' "$WFAUDIT"; then
      info "Injection PIP_CONSTRAINT pour les étapes pip install…"
      awk '{
        gsub(/\r$/, "");
        if ($0 ~ /pip install / && $0 !~ /PIP_CONSTRAINT=constraints\/security-pins\.txt/) {
          sub(/pip install /, "PIP_CONSTRAINT=constraints/security-pins.txt pip install ")
        }
        print
      }' "$WFAUDIT" > "$WFAUDIT.tmp" && mv "$WFAUDIT.tmp" "$WFAUDIT"
      touched=true
    else
      warn "Aucune commande 'pip install' trouvée dans $WFAUDIT (rien à contraindre)."
    fi
  fi

  [[ "$touched" == true ]] && changed+=("$WFAUDIT") || info "Aucun changement requis pour $WFAUDIT"
else
  warn "Absent (ok) : $WFAUDIT"
fi

# 3) Ajouter concurrency à codeql.yml si manquant
if [[ -f "$WFQL" ]]; then
  if grep -Eq '^[[:space:]]*concurrency:[[:space:]]*$' "$WFQL"; then
    info "Concurrency déjà présent dans $WFQL"
  else
    info "Ajout du bloc concurrency à $WFQL"
    printf '\nconcurrency:\n  group: codeql-${{ github.ref }}\n  cancel-in-progress: true\n' >> "$WFQL"
    changed+=("$WFQL")
  fi
else
  warn "Absent (ok) : $WFQL"
fi

# 4) Commit ciblé & push si nécessaire
if (( ${#changed[@]} )); then
  info "Fichiers modifiés: ${changed[*]}"
  git add -- "${changed[@]}"
  git commit -m "ci: stabilize pip-audit (PIP_CONSTRAINT, spinner off) & add CodeQL concurrency"
  git push
else
  info "Aucun changement à committer."
fi

# 5) Aperçu rapide (1..120)
for f in "$WFAUDIT" "$WFQL"; do
  [[ -f "$f" ]] || continue
  echo "──────── $f (aperçu 1..120)"
  nl -ba "$f" | sed -n '1,120p' | sed 's/^/    /'
done

info "Terminé."
