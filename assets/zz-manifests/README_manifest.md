# MCGT — Manifestes de publication

## But

Ce dossier contient :

* `manifest_publication.json` : manifeste **final** publié (chemins **relatifs**).
* `manifest_master.json` : manifeste **maître** (inventaire complet, éventuellement plus verbeux).
* `meta_template.json` : gabarit de **métadonnées** d’artefacts.
* `diag_consistency.py` : **audit** & **correction** automatiques des manifestes.
* `add_to_manifest.py` : enregistrement **incrémental** d’un fichier dans `manifest_master.json`.
* `manifest_report.md` : **rapport** lisible généré après audit.
* `chapters/` : manifestes par **chapitre** (ex. `chapters/chapter_manifest_09.json`).
* *(optionnel)* `manifest_publication.json.sig` / `.sha256sum` : **signature** & **intégrité**.

> **Outils requis** : `python3`, `git`.
> **Optionnels** : `gpg`, `sha256sum` (ou équivalent).
> **Tous les chemins sont relatifs à la racine du dépôt** (`.`).

---

## Principes & conventions

* Tous les **noms de fichiers** et **chemins** dans les manifestes sont en **anglais** (ex. `assets/zz-data/chapter09/...`, `assets/zz-figures/chapter10/...`, `scripts/07_bao_geometry/...`).
  *Exception :* les sources LaTeX `*.tex` conservent les noms en **français** (ex. `09_phase_ondes_grav_conceptuel.tex`).
* Les manifestes peuvent exister en **deux formats** :

  * **Master** (inventaire complet) : clé `files: [...]` (format léger, sans typage détaillé).
  * **Publication** (sélection) : clé `entries: [...]` (format riche avec `role`, `kind`, `format`, `chapter`, etc.).
* Les métadonnées d’artefacts suivent `assets/zz-manifests/meta_template.json`.
  Les **règles** de cohérence inter-projet (constantes canoniques, fenêtres, classes) sont dans `assets/zz-manifests/migration_map.json`.

---

## Schémas (résumé)

### A) `manifest_master.json` (léger)

```json
{
  "manifest_version": "1.0",
  "project": "MCGT",
  "generated_at": "UTC-ISO8601",
  "files": [
    {
      "path": "assets/zz-data/chapter09/09_metrics_phase.json",
      "role": "data|config|code|figure|document|meta",
      "sha256": "<hex>",
      "size_bytes": 1234,
      "mtime_iso": "UTC-ISO8601"
    }
  ]
}
```

### B) `manifest_publication.json` (riche)

```json
{
  "spec_version": "1.0.0",
  "repository_root": ".",
  "release_tag": "publication-vX",
  "generated_at": "UTC-ISO8601",
  "licenses": { "docs": {...}, "code": {...}, "data": {...} },
  "selection_policy": { "include": [...], "exclude": [...] },
  "entries": [
    {
      "path": "assets/zz-figures/chapter09/09_fig_01_phase_overlay.png",
      "role": "figure",
      "kind": "png",
      "format": "png",
      "chapter": 9,
      "why": "figure représentative",
      "size_bytes": 420082,
      "sha256": "<hex>",
      "mtime_iso": "UTC-ISO8601",
      "git_hash": "<blob-or-null>"
    }
  ]
}
```

> **Bonnes pratiques**
>
> * `path` **relatif** (jamais absolu).
> * `sha256` et `size_bytes` **obligatoires** dans la version publiée.
> * `git_hash` si le fichier est suivi par Git.
> * Garder la **cohérence linguistique** : `chapterXX`, `generate_*`, `results`, `config`, etc.

---

## Procédure standard (release)

1. **Audit initial (sans modification)**

```bash
python3 assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_publication.json \
  --repo-root . --report text --fail-on errors --content-check
```

2. **Application de corrections techniques**

```bash
python3 assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_publication.json \
  --repo-root . --fix --normalize-paths --strip-internal --set-repo-root
```

3. **Normalisation des chemins via alias (FR→EN) si applicable**

> Nécessite des alias dans `assets/zz-manifests/migration_map.json` (ex. `assets/zz-data/chapitre` → `assets/zz-data/chapter`).

```bash
python3 assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_publication.json \
  --repo-root . --apply-aliases --fix
```

4. **Vérification de contenu (fenêtres/métriques/classes)**

```bash
python3 assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_publication.json \
  --repo-root . --report md --content-check > assets/zz-manifests/manifest_report.md
```

5. **Empreinte & signature (recommandé)**

```bash
python3 assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_publication.json --sha256-out
python3 assets/zz-manifests/diag_consistency.py assets/zz-manifests/manifest_publication.json --gpg-sign
```

6. **Commit & tag**

```bash
git add assets/zz-manifests/manifest_publication.json assets/zz-manifests/manifest_report.md \
        assets/zz-manifests/*.sig assets/zz-manifests/*.sha256sum
git commit -m "chore(manifest): publication-vX"
git tag -a publication-vX -m "Publication vX"
```

---

## Mises à jour incrémentales (ajout de fichiers)

### Ajouter un fichier individuel au master

```bash
python3 assets/zz-manifests/add_to_manifest.py assets/zz-data/chapter09/09_metrics_phase.json --role data
```

### Regénérer un sous-ensemble (ex. chapitres 9–10) puis rafraîchir le master

```bash
# (exécution des pipelines de génération en amont)
python3 assets/zz-manifests/add_to_manifest.py assets/zz-figures/chapter09/09_fig_02_residual_phase.png --role figure
python3 assets/zz-manifests/add_to_manifest.py assets/zz-data/chapter10/10_mc_results.csv --role data
```

### Re-synchroniser la version publication à partir du master (outil dédié)

```bash
python3 scripts/manifesttools/populate_manifest.py \
  --master assets/zz-manifests/manifest_master.json \
  --publication assets/zz-manifests/manifest_publication.json \
  --policy include=tex_sources,chapter_guides,global_configs,key_scripts,mcgt_modules,representative_figures,meta_files \
           exclude=raw_heavy_data,mc_samples_large,cache_dirs,temporary_files,topk_residus
```

> **Astuce** : les cibles du `Makefile` existent en alias
> `make manifestscheck` · `make manifests-md` · `make qa`

---

## Règles de sélection (publication)

**Inclure** :

* Sources LaTeX (`manuscript/main.tex` + chapitres `*.tex`)
* Guides de chapitre (`CHAPTERXX_GUIDE.txt`)
* Configs essentielles (`config/mcgt-global-config.ini`, `config/*.ini`, `config/*.json`)
* Scripts clés (`scripts/chapterXX/generate_*.py`, traceurs `plot_*.py`)
* Modules `mcgt/` (`__init__.py`, `phase.py`, `scalar_perturbations.py`, backends)
* Figures **représentatives** (`assets/zz-figures/chapterXX/fig_*.png`)
* Fichiers `*.meta.json` **associés**

**Exclure** :

* Données brutes volumineuses (`assets/zz-data/chapterXX/*samples*.csv`, caches temporaires)
* Fichiers intermédiaires et artefacts non déterministes
* Archives et sauvegardes (`*.bak*`, `*.tmp`, `*.log`)

---

## Champs techniques (rappel)

* `size_bytes` : taille octets réelle.
* `sha256` : empreinte hex SHA-256 du fichier publié.
* `mtime_iso` : dernière modification (UTC, ISO-8601).
* `git_hash` : hash Git de l’objet (si suivi par Git).
* `role` : `data|config|code|figure|document|meta|script|bibliography`.
* `kind/format` : extension logique (`json`, `csv`, `png`, `ini`, `py`, `tex`, `bib`, …).
* `chapter` : entier 1–10 si pertinent.
* `why` : justification courte (« figure représentative », « config globale », …).

---

## Dépannage rapide

* **ABSOLUTE\_PATH** : une entrée a un chemin absolu → convertir en **relatif**.
* **FILE\_MISSING** : fichier absent → corriger la cible ou retirer l’entrée.
* **SHA\_MISMATCH** : empreinte obsolète → exécuter `--fix`.
* **GIT\_HASH\_UNAVAILABLE** : acceptable hors Git / fichiers ignorés.
* **PATH\_ALIAS\_CANDIDATE** : l’alias FR→EN existe → relancer avec `--apply-aliases`.
* **CLASS\_LABEL\_UNKNOWN** (jalons chap. 9) : normaliser via `--fix-content` selon `assets/zz-manifests/migration_map.json`.

---

## Références utiles

* Gabarit méta : `assets/zz-manifests/meta_template.json`
* Règles de cohérence : `assets/zz-manifests/migration_map.json`
* Config globale : `config/mcgt-global-config.ini`
* Makefile (cibles QA/manifests) : `Makefile`

---

## Licence

* **Docs** : CC-BY-SA-4.0
* **Code** : MIT
* **Données** : CC0-1.0

> Pour toute question : *Contact technique* (mainteneur scripts/CI) & *contact scientifique* (responsable MCGT).
