# Release checklist mcgt-core

1. `git pull` (main à jour)
2. `scripts/release.sh X.Y.Z`
3. Vérifier:
   - GH Actions: build + "Publish to PyPI" ⇒ OK
   - `pip index versions mcgt-core` liste X.Y.Z
   - `VER=X.Y.Z ./phase4_validate.sh` ⇒ OK
4. Rédiger changelog si nécessaire et tag suivant prêt.
