#!/usr/bin/env bash
set -euo pipefail

echo "== Cleanup backups (Makefile.bak.* & manifest .bak.*) =="
[ -d .git ] || { echo "❌ Lance à la racine du dépôt (.git/)."; exit 2; }

# Liste candidates déjà versionnées
git ls-files 'Makefile.bak.*' 'zz-manifests/manifest_master.json.bak.*' | sed -n '1,200p' || true

# Supprime si présents
git rm -f $(git ls-files 'Makefile.bak.*' 'zz-manifests/manifest_master.json.bak.*') 2>/dev/null || true

# Supprime aussi les copies non suivies (sécurité)
rm -f Makefile.bak.* zz-manifests/manifest_master.json.bak.* 2>/dev/null || true

# Commit + push si des suppressions ont eu lieu
if ! git diff --cached --quiet; then
  git commit -m "chore: cleanup backup files (Makefile.bak.*, manifest_master.json.bak.*)"
  git push origin HEAD
  echo "✅ Backups nettoyés et poussés."
else
  echo "ℹ️  Rien à nettoyer."
fi
