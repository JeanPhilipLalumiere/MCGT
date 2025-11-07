#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[apply-ciout-guards] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[apply-ciout-guards] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"

# =====================================================================
# 1) .gitattributes : s’assurer de ".ci-out export-ignore" (idempotent)
# =====================================================================
GITATTR=".gitattributes"
[[ -f "$GITATTR" ]] || echo "# Attributes auto-générés" > "$GITATTR"
# Trailing newline si absent
tail -c1 "$GITATTR" | read -r _ || echo >> "$GITATTR"
# Ajoute la règle si manquante
if ! grep -qE '^[[:space:]]*\.ci-out[[:space:]]+export-ignore[[:space:]]*$' "$GITATTR"; then
  echo ".ci-out export-ignore" >> "$GITATTR"
  echo "INFO:  Ajouté à .gitattributes : '.ci-out export-ignore'"
else
  echo "INFO:  Déjà présent dans .gitattributes : '.ci-out export-ignore'"
fi

# ==========================================================
# 2) Workflow CI: .github/workflows/meta-guard.yml (idempotent)
#    Vérifie que .ci-out n’apparaît pas dans l’archive git
# ==========================================================
mkdir -p .github/workflows
cat > .github/workflows/meta-guard.yml <<'YAML'
name: meta-guard
on:
  push:
  pull_request:
jobs:
  export-ignore:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verify .ci-out is not in source archive
        run: |
          git archive -o /tmp/test.zip HEAD
          if unzip -l /tmp/test.zip | grep -q '\.ci-out/'; then
            echo "::error::.ci-out leaked into archive"
            exit 1
          fi
YAML
echo "INFO:  Écrit/actualisé: .github/workflows/meta-guard.yml"

# ==========================================================
# 3) pre-commit: ajouter 2 hooks locaux (idempotent)
#    - Forbid .ci-out en index
#    - Ensure .gitattributes a 'export-ignore'
# ==========================================================
PCC=".pre-commit-config.yaml"
if [[ ! -f "$PCC" ]]; then
  echo "repos:" > "$PCC"
  echo "INFO:  Créé squelette .pre-commit-config.yaml"
fi

# S’assurer que la clé 'repos:' existe (au début du fichier)
if ! grep -qE '^[[:space:]]*repos:[[:space:]]*$' "$PCC"; then
  tmp="$(mktemp)"
  printf "repos:\n" > "$tmp"
  cat "$PCC" >> "$tmp"
  mv "$tmp" "$PCC"
  echo "INFO:  Ajout de la clé 'repos:' en tête du fichier"
fi

# Remplacer proprement notre bloc entre marqueurs si déjà présent
MARK_S="# BEGIN auto-guards"
MARK_E="# END auto-guards"
if grep -qF "$MARK_S" "$PCC"; then
  awk -v s="$MARK_S" -v e="$MARK_E" '
    BEGIN{skip=0}
    $0==s {skip=1; next}
    $0==e {skip=0; next}
    skip==0 {print}
  ' "$PCC" > "$PCC.tmp" && mv "$PCC.tmp" "$PCC"
  echo "INFO:  Ancien bloc auto-guards supprimé (remplacement)."
fi

# Trailing newline si absent
tail -c1 "$PCC" | read -r _ || echo >> "$PCC"

# Appendre notre bloc (style compatible pre-commit)
cat >> "$PCC" <<'YAML'
# BEGIN auto-guards
- repo: local
  hooks:
    - id: forbid-ci-out-in-index
      name: Forbid .ci-out in index
      entry: bash -lc 'git diff --cached --name-only | grep -qE "^\.ci-out/" && { echo ".ci-out must not be committed"; exit 1; } || exit 0'
      language: system
      pass_filenames: false
      stages: [commit]

    - id: ensure-gitattributes-export-ignore
      name: Ensure .gitattributes has .ci-out export-ignore
      entry: bash -lc 'grep -qE "^[[:space:]]*\.ci-out[[:space:]]+export-ignore[[:space:]]*$" .gitattributes || { echo "Missing .ci-out export-ignore in .gitattributes"; exit 1; }'
      language: system
      pass_filenames: false
      stages: [commit]
# END auto-guards
YAML
echo "INFO:  Hooks locaux ajoutés dans .pre-commit-config.yaml"

# ==========================================================
# 4) Validation rapide (best-effort) et message final
# ==========================================================
if command -v pre-commit >/dev/null 2>&1; then
  if pre-commit validate-config >/dev/null 2>&1; then
    echo "INFO:  pre-commit config valide ✔"
  else
    echo "WARN:  pre-commit validate-config a échoué — vérifie manuellement."
  fi
else
  echo "WARN:  'pre-commit' introuvable dans le PATH (validation sautée)."
fi

echo "✅ apply-ciout-guards: terminé."
