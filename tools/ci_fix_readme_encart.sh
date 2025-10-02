#!/usr/bin/env bash
# Met à jour un encart CI dans README.md entre deux marqueurs.
# - S'il n'y a pas de marqueurs, l'encart est ajouté en fin de fichier.
# - Contenu minimal et stable pour éviter les faux positifs shfmt/shellcheck.
set -Eeuo pipefail

cleanup() {
  local rc="$1"
  echo
  echo "=== FIN DU SCRIPT (code=$rc) ==="
  if [[ "${PAUSE_ON_EXIT:-1}" != "0" && -t 1 && -t 0 ]]; then
    read -rp "Appuyez sur Entrée pour fermer cette fenêtre..." _ || true
  fi
}
trap 'cleanup $?' EXIT

# Fichier cible (par défaut README.md)
OUT_FILE="${1:-README.md}"

BEGIN_MARK="<!-- BEGIN: ENCART CI -->"
END_MARK="<!-- END: ENCART CI -->"

# Contenu de l'encart (simple, déterministe)
now_utc="$(date -u +'%Y-%m-%d %H:%M:%SZ')"
tmp_encart="$(mktemp)"
cat >"$tmp_encart" <<EOF
$BEGIN_MARK

> Encadré CI généré automatiquement — $now_utc

- **pre-commit** : hooks check-yaml, trailing-whitespace, shellcheck, shfmt, etc.
- **Workflows** : \`sanity-main.yml\`, \`ci-pre-commit.yml\`
- **Garde-fou SC2129** : appends regroupés vers \\\$GITHUB_STEP_SUMMARY

$END_MARK
EOF

tmp_new="$(mktemp)"
if [[ -f "$OUT_FILE" ]]; then
  if grep -qF "$BEGIN_MARK" "$OUT_FILE" && grep -qF "$END_MARK" "$OUT_FILE"; then
    # Remplace la section existante (BEGIN..END) par le nouveau bloc
    # On insère *le fichier* tmp_encart (qui contient aussi les marqueurs).
    sed -e "/${BEGIN_MARK}/,/${END_MARK}/{
      /${BEGIN_MARK}/{r ${tmp_encart}
        d
      }
      /${END_MARK}/d
    }" "$OUT_FILE" >"$tmp_new"
  else
    # Ajoute l'encart à la fin
    cat "$OUT_FILE" >"$tmp_new"
    printf '\n' >>"$tmp_new"
    cat "$tmp_encart" >>"$tmp_new"
  fi
else
  # Crée le README avec l'encart
  cat "$tmp_encart" >"$tmp_new"
fi

if cmp -s "$OUT_FILE" "$tmp_new"; then
  echo "[INFO] Aucun changement dans $OUT_FILE"
  rm -f "$tmp_encart" "$tmp_new"
  exit 0
fi

mv "$tmp_new" "$OUT_FILE"
rm -f "$tmp_encart"
echo "[OK] $OUT_FILE mis à jour."
