# Check-list Zenodo (finalisation DOI)

1) Vérifier que l'intégration GitHub↔Zenodo est activée pour `JeanPhilipLalumiere/MCGT`.
2) Le tag **v0.3.0** est publié (OK). Zenodo va archiver la release et **minter un DOI** (concept DOI + DOI de la version).
3) Récupérer le DOI de la version (ex: `10.5281/zenodo.1234567`).
4) Injecter ce DOI dans les fichiers :
   sh
   python archives/tools_legacy_20260309/tools/backfill_zenodo_doi.py 10.5281/zenodo.1234567
   git add README.md CITATION.cff
   git commit -m "docs: backfill Zenodo DOI v0.3.0"
   git push

5) (Optionnel) Re-générer un tarball si besoin et rattacher à la release GitHub (Zenodo liera déjà la release).
6) Le badge Zenodo dans le README s'actualisera automatiquement après backfill.
