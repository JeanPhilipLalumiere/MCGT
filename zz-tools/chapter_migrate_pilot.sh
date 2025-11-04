#!/usr/bin/env bash
set -Eeuo pipefail

CH="${1:-chapter08}"
echo "[INFO] Pilote homogénéisation → $CH (dry-run)"
# 0) garde méta JSON sur les figures du chapitre (si elles lisent un .json meta)
for f in zz-scripts/$CH/*.py; do
  grep -q "json.load" "$f" && python3 zz-tools/codemod_meta_guard.py "$f" || true
done

# 1) tight_layout → subplots_adjust (dry-run)
python3 zz-tools/codemod_tightlayout.py zz-scripts/$CH/*.py || true

# 2) (optionnel) diagnostic alias CSV : on n’écrit rien, on liste juste les occurences de read_csv
grep -Hn "read_csv" zz-scripts/$CH/*.py || true

echo "[OK] Pilote dry-run terminé pour $CH."
echo "→ Si tout est propre, relancer avec: python3 zz-tools/codemod_tightlayout.py --write zz-scripts/$CH/*.py"
