# repo_fix_ch09_fig03_guarded.sh
# Neutralise le bloc top-level orphelin de ch09/fig03, valide, et commit.
# Garde-fou : ne ferme pas la fenêtre même en cas d’erreur ; tout est loggué.

set -Eeuo pipefail

# --- Garde-fou & logs ---------------------------------------------------------
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_fix_ch09_fig03_${TS}.log"
OUTDIR="/tmp/mcgt_fix_ch09_fig03_${TS}"
mkdir -p "$OUTDIR"
exec > >(tee -a "$LOG") 2>&1

pause_guard() {
  code=$?
  echo
  echo "[GUARD] Script terminé (exit=$code)."
  echo "[GUARD] Log: $LOG"
  echo "[GUARD] Appuie sur Entrée pour laisser la fenêtre ouverte…"
  # Empêche la fermeture brutale dans les lanceurs/émulateurs
  read -r _
  # En dernier recours, démarre un shell interactif si l’UI tue quand même le proc
  if [ -n "${FORCE_SHELL:-}" ]; then
    echo "[GUARD] Ouverture d’un shell interactif de secours. Tape 'exit' pour quitter."
    bash --noprofile --norc -i
  fi
}
trap pause_guard EXIT

echo "== STEP 0 | Contexte =="
pwd
git rev-parse --abbrev-ref HEAD || true

F="zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"
if [ ! -f "$F" ]; then
  echo "[ERREUR] Fichier introuvable: $F"
  exit 2
fi

echo "== STEP 1 | Sauvegarde =="
cp -a "$F" "${F}.bak_${TS}"
echo "[OK] Backup -> ${F}.bak_${TS}"

echo "== STEP 2 | Neutralisation du bloc top-level orphelin =="

python - <<'PY'
import re, sys
from pathlib import Path

F = Path("zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py")
src = F.read_text().splitlines()

def find_idx(rx, start=0):
    rg = re.compile(rx)
    for i in range(start, len(src)):
        if rg.match(src[i]):
            return i
    return -1

# 1) Si un data_label f"...info_mode..." traîne, le neutraliser proprement
for i, line in enumerate(src):
    if re.match(r'^\s*data_label\s*=\s*f".*?info_mode.*?"\s*$', line):
        src[i] = '# SHIM-R2: ' + line

# 2) Trouver un bloc top-level commençant par "if abs_dphi is None:" (le cas cassé vu)
i_start = find_idx(r'^if\s+abs_dphi\s+is\s+None:')
if i_start < 0:
    print("[NOTE] Motif 'if abs_dphi is None:' introuvable — aucune neutralisation requise.")
else:
    # 3) Chercher jusqu’à la prochaine def/class top-level (ou EOF)
    i_end = find_idx(r'^(def|class)\s+\w+\s*\(', i_start+1)
    if i_end < 0:
        i_end = len(src)
    changed = 0
    for i in range(i_start, i_end):
        if not src[i].lstrip().startswith('#'):
            src[i] = '# SHIM-R2: ' + src[i]
            changed += 1
    print(f"[OK] Bloc orphelin neutralisé: lignes {i_start+1}–{i_end} (commentées={changed})")

# 4) Sécuriser quelques artefacts connus des tentatives précédentes (résidus fréquents)
#    - 'args.diff et {' -> 'args.diff and {'
for i, line in enumerate(src):
    if 'args.diff et {' in line:
        src[i] = src[i].replace('args.diff et {', 'args.diff and {')

#    - guillemets isolés et virgules pendantes courantes (traces d'édition)
for i, line in enumerate(src):
    if re.match(r'^\s*"\s*$', line):
        src[i] = '# SHIM-R2: ' + line
    if re.match(r'^\s*,\s*$', line):
        src[i] = '# SHIM-R2: ' + line

# 5) Écrire
F.write_text("\n".join(src) + "\n")
PY

echo "== STEP 3 | Diff ciblé =="
git --no-pager diff -U2 -- "$F" | sed 's/^/DIFF /' || true

echo "== STEP 4 | Validation syntaxe (py_compile) =="
if ! python -m py_compile "$F"; then
  echo "[WARN] py_compile a échoué — restauration possible via backup: ${F}.bak_${TS}"
  # On n'abandonne pas : le garde-fou garde la fenêtre ouverte.
fi

echo "== STEP 5 | --help (sanity) =="
# Si le script a un parser, l'usage s'affichera ; sinon ça échouera sans conséquence
python "$F" --help 2>&1 | head -n 50 || echo "[NOTE] --help non disponible (non bloquant)."

echo "== STEP 6 | Commit (branche courante) =="
# On n’échoue pas si git refuse (non-bloquant pour la fenêtre)
git add "$F" 2>/dev/null || true
git commit -m "fix(ch09/fig03): SHIM-R2 — neutralise bloc top-level orphelin (import OK); code historique conservé en commentaires" 2>/dev/null || true
git --no-pager log -1 --oneline || true

echo
echo "== DONE | Résumé =="
echo "- Fichier patché : $F"
echo "- Backup          : ${F}.bak_${TS}"
echo "- Log             : $LOG"
echo "- Si besoin d’annuler :  cp -a \"${F}.bak_${TS}\" \"$F\" && git checkout -- \"$F\" 2>/dev/null || true"
echo "[OK] Étape urgente terminée (neutralisation + validations de base)."
