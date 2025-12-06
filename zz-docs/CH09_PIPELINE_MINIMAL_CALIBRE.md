# Chapitre 09 – Pipeline minimal calibré (phase gravitationnelle)

Ce document décrit **le pipeline minimal “canonique”** pour reproduire rapidement
les principaux produits du Chapitre 09 (analyse de phase IMRPhenom vs MCGT),
en s'appuyant sur le script existant :

```bash
bash zz-tools/smoke_ch09_fast.sh
```

L'objectif est d'avoir **un chemin court, reproductible et documenté**
pour :

- recalculer `09_metrics_phase.json` ;
- régénérer les figures de phase principales ;
- vérifier rapidement que la chaîne de calcul CH09 est fonctionnelle.

---

## 1. Pré‑requis

Depuis la racine du dépôt `MCGT` :

- L’environnement Python `mcgt-dev` doit être activé (ou un équivalent contenant
  les dépendances MCGT) ;
- Les fichiers de configuration et de données externes suivants existent déjà
  (ils sont suivis dans les manifests) :

  - `zz-configuration/GWTC-3-confident-events.json`
  - `zz-data/chapter09/gwtc3_confident_parameters.json`
  - `zz-data/chapter09/09_phases_mcgt.csv` (référence de phase MCGT, déjà construite)

Ces fichiers sont déjà en place dans l’état courant du dépôt et utilisés par
les scripts de CH09.

---

## 2. Pipeline minimal calibré – commande unique

Depuis la racine du dépôt :

```bash
cd /home/jplal/MCGT  # adapter si nécessaire
bash zz-tools/smoke_ch09_fast.sh
```

Ce script effectue automatiquement les étapes suivantes (résumé basé sur les logs
actuels) :

1. **Chargement de la référence IMRPhenom** et des phases MCGT (`09_phases_mcgt.csv`) ;
2. **Calage de la phase** (`φ0`, `t_c`) par ajustement pondéré (poids en `1/f²`) ;
3. **Contrôle de la dispersion** `p95(|Δφ|)` sur la bande [20, 300] Hz ;
4. Si besoin, **resserrage automatique** de la fenêtre de fit (typiquement vers
   [30, 250] Hz) puis nouveau calage ;
5. **Écriture des métriques** dans :

   ```text
   zz-data/chapter09/09_metrics_phase.json
   ```

6. **Génération des figures de phase** :

   - `zz-figures/chapter09/09_fig_01_phase_overlay.png`
   - `zz-figures/chapter09/09_fig_02_residual_phase.png`

7. **Préparation des données intermédiaires** pour fig. 02 :

   - `zz-out/chapter09/fig02_input.csv`
   - éventuelles variantes normalisées associées.

---

## 3. Produits attendus après exécution

Après `bash zz-tools/smoke_ch09_fast.sh`, on doit trouver au minimum :

### 3.1 Données de phase

- `zz-data/chapter09/09_metrics_phase.json`  
  Contient notamment :

  - la variante de phase active (`"variant": "phi_mcgt"` ou similaire) ;
  - les statistiques de dispersion sur 20–300 Hz (moyenne, p95, max) ;
  - des informations sur la fenêtre de calibration utilisée.

Les fichiers suivants sont considérés comme **référence stable** (et ne sont pas
écrasés sauf option explicite) :

- `zz-data/chapter09/09_phases_mcgt.csv`
- `zz-data/chapter09/gwtc3_confident_parameters.json`

### 3.2 Figures

- `zz-figures/chapter09/09_fig_01_phase_overlay.png`  
  Superposition IMRPhenom / MCGT, avec calibration optimisée.

- `zz-figures/chapter09/09_fig_02_residual_phase.png`  
  Résidu `Δφ(f) = φ_MCGT(f) − φ_ref(f)` sur la bande 20–300 Hz, après rebranch
  éventuel d’un nombre entier de cycles `k`.

### 3.3 Données intermédiaires pour fig. 02

- `zz-out/chapter09/fig02_input.csv`  
  Contient les colonnes numériques utilisées pour la figure de résidu, par
  exemple `(f_Hz, phi_ref, phi_mcgt, dphi)`.

---

## 4. Notes sur la calibration automatique

Les logs du pipeline (tels qu’observés dans les exécutions récentes) suivent
grosso modo le schéma :

```text
[INFO] Paramètres MCGT: PhaseParams(...)
[INFO] Référence existante utilisée (N pts).
[INFO] Calage phi0_tc (poids=1/f2): φ0=..., t_c=... (window=[20.0, 300.0])
[INFO] Contrôle p95 avant resserrage: p95(|Δφ|)@[20.0-300.0]=... rad (seuil=5.000)
[INFO] Resserrement automatique: refit sur [30.0, 250.0] Hz.
[INFO] Calage phi0_tc (...): φ0=..., t_c=... (window=[30.0, 250.0])
[INFO] Après resserrage: p95(|Δφ|)@[20.0-300.0]=... rad
...
[INFO] |Δφ| 20–300 Hz (après rebranch k=1): mean=..., p95=..., max=...
[INFO] Figure enregistrée → zz-figures/chapter09/09_fig_01_phase_overlay.png
[INFO] Figure enregistrée → zz-figures/chapter09/09_fig_02_residual_phase.png
```

Les points importants :

- Le script **peut conserver les fichiers existants** (`09_phases_mcgt.csv`) et
  ne les écraser qu’avec une option explicite (`--overwrite`) si elle est prévue ;
- La variante active (par ex. `phi_mcgt`) et les statistiques (`mean`, `p95`,
  `max`) sont **stockées dans `09_metrics_phase.json`** et servent de référence
  pour le contrôle de qualité du Chapitre 09.

---

## 5. Intégration avec la garde globale MCGT

Le pipeline ci‑dessus est déjà intégré dans :

- `zz-tools/smoke_ch09_fast.sh` (smoke ciblé CH09) ;
- `zz-tools/smoke_all_skeleton.sh` (smoke global squelette) ;
- `tools/mcgt_step01_guard_diag_smoke.sh` (garde‑fou global diag + smoke).

Ce document sert de **référence humaine** :

- pour comprendre rapidement ce que couvre le “smoke CH09 (fast)” ;
- pour vérifier que les produits attendus sont en place **avant** une exécution
  complète de la chaîne MCGT ou avant une future publication.

