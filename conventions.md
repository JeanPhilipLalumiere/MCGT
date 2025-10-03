# CONVENTION MCGT

Version : 1.1
Portée : ce document définit les **conventions de données, de métadonnées, d’unités, de nommage et de validation** applicables à l’ensemble des 10 chapitres MCGT (01–10). Il accompagne `zz-configuration/mcgt-global-config.ini` et les schémas dans `zz-schemas/`.

---

## 1) Arborescence & nommage

### 1.1 Répertoires canoniques

* **Données** : `zz-data/chapter{N}/`
  *ex.* `zz-data/chapter07/07_perturbations_domain.csv`
* **Figures** : `zz-figures/chapter{N}/`
  *ex.* `zz-figures/chapter03/fig_07_ricci_fR_vs_z.png`
* **Scripts** : `zz-scripts/chapter{N}/`
  *ex.* `zz-scripts/chapter06/generate_data_chapter06.py`
* **Configuration** : `zz-configuration/`
  *ex.* `gw_phase.ini`, `scalar_perturbations.ini`, `camb_exact_plateau.ini`
* **Schémas** : `zz-schemas/`
  *ex.* `mc_config_schema.json`, `metrics_phase_schema.json`, `mc_results_table_schema.json`
* **Manifests** : `zz-manifests/`
  *ex.* `manifest_master.json`, `manifest_publication.json`, `diag_consistency.py`

> **Aliases et compatibilité** : les chemins historiques (ex. `zz-donnees/chapitre*`) peuvent encore exister. Leur résolution est décrite dans `zz-schemas/consistency_rules.json` (section *aliases*).

### 1.2 Règles de nommage (fichiers)

* Préfixe **à deux chiffres** = **chapitre** (01–10).
  *ex.* `07_cs2_matrix.csv`, `09_phases_mcgt.csv`, `10_mc_results.csv`.
* **Tous les noms de fichiers** (données, scripts, schémas, manifests) sont **en anglais**.
  **Seule exception :** les sources LaTeX (`.tex`) conservent leurs noms français.
* Figures : `fig_XX_<descriptor>.png` (numérotation stable par chapitre).
* CSV/JSON : en-têtes `snake_case` ASCII, stables et documentés.

### 1.3 Manifests (ZZ)

Emplacement canonique : `zz-manifests/`

Fichiers :

* `meta_template.json`
* `manifest_master.json` (inventaire de référence, complet)
* `manifest_publication.json` (+ sauvegardes `*.bak` horodatées)
* `manifest_report.json` (rapport généré)
* `diag_consistency.py` (audit / correction optionnelle)
* `README_manifest.md`

**Règles minimales**

* Chaque artefact important (CSV/DAT/JSON/PNG/PDF) doit apparaître dans `manifest_master.json` avec `path` (relatif à la racine), `sha256`, `size_bytes`, `mtime_iso`.
* Les `*.meta.json` doivent inclure `manifest_entry` (référence à l’entrée correspondante du manifest).
* `diag_consistency.py` :
  vérifie existence, tailles, SHA-256, `mtime_iso`, *git hash* (si disponible), chemins relatifs ; peut corriger (`--fix`) et signer/sommer (`--gpg-sign`, `--sha256-out`).

---

## 2) Unités & notations

### 2.1 Unités

* Fréquence (GW) : `f_Hz` en **hertz**.
* Multipôles (CMB) : `ell` (entiers ≥ 2).
* Angles de phase : **radians** (suffixer `_rad` si ambigu).
* Distances (MC 8D) : `dist` en **Mpc** (par défaut).
* Temps cosmologique & température/redshift : selon contexte du chapitre (documentés dans les `.meta.json`).

### 2.2 Grandeurs récurrentes

* **Écart relatif** :

  $$
  \epsilon_{\mathrm{rel}}=\frac{x_{\mathrm{mod}}-x_{\mathrm{ref}}}{x_{\mathrm{ref}}}
  $$

  (sans unité).
* **|Δφ| (chap. 9–10)** : écart absolu de phase (radians), calculé sur le **résidu principal** (déf. §6).
* **p95** : 95ᵉ percentile d’une distribution de |Δ…| dans une fenêtre donnée.
  Suffixes : `_raw` (avant calibration), `_cal` (après calibration φ₀,t\_c), `_poly` (après correction poly), `_circ` (statistiques circulaires).

---

## 3) Métadonnées obligatoires (`*.meta.json`)

Champs requis pour chaque pipeline :

* `generated_at` (ISO-8601 UTC)
* `git_hash` (commit SHA ; `null` toléré hors repo → *WARN*)
* `config_used` (chemin relatif `.ini`/`.json`)
* `python` (ex. `"3.12.3"`) et `libs` (versions majeures)
* `n_points` (déclarés) et `actual_n_points` (observés)
* `grid` (si pertinent) : `fmin_Hz`, `fmax_Hz`, `dlog10`, etc.
* `checksum_sha256` : dict `{ "rel/path": "sha256hex" }`
* `files` : liste exhaustive des sorties
* `manifest_entry` : pointeur vers `manifest_master.json`

Des schémas valident ces structures : voir `zz-schemas/meta_schema.json`, `metrics_phase_schema.json`, etc.

---

## 4) Seuils & classes

* **Globaux (défaut)** :
  `thresholds.primary = 0.01`, `thresholds.order2 = 0.10`.
* **Spécifiques chapitres (override si documenté)** :
  Chap. 5 (BBN) — seuils propres à DH/Yp (voir données/figure du chapitre).
  Chap. 9 — contrôle par `p95` sur **\[20,300] Hz** (objectif de serrage : `tighten_threshold_p95_rad = 5.0`).

---

## 5) Spécifications de fichiers (formats, exemples canoniques)

### 5.1 Chapitres 1–2 (chronologie / spectre)

* `zz-data/chapter01/01_dimensionless_invariants.csv` : `T_Gyr,I1,I2,I3`
* `zz-data/chapter02/02_optimal_parameters.json` (paramètres α → A\_s,n\_s)
* `zz-data/chapter02/02_primordial_spectrum_spec.json` (spécification)

### 5.2 Chapitre 3 (stabilité f(R))

* `03_fR_stability_data.csv` : `R_over_R0,f_R,f_RR,m_s2_over_R0`
* `03_fR_stability_domain.csv` : `beta,gamma_min,gamma_max`
* `03_ricci_fR_vs_{T,z}.csv` : `R_over_R0,f_R,f_RR,T_Gyr|z`

### 5.3 Chapitre 4 (invariants)

* `04_dimensionless_invariants.csv` : `T_Gyr,I1,I2,I3`
* `04_P_vs_T.dat` : `T,P_calc`

### 5.4 Chapitre 5 (BBN)

* `05_nucleosynthesis_parameters.json`
* `05_bbn_grid.csv`, `05_bbn_data.csv`, `05_bbn_invariants.csv`
* `05_chi2_bbn_vs_T.csv`, `05_dchi2_vs_T.csv`

### 5.5 Chapitre 6 (CMB)

* `06_cmb_full_results.csv` : `ell,cl_lcdm,cl_mcgt,delta_cls,delta_cls_rel`
* `06_cls_spectrum.dat`
* Scans : `06_delta_cls*.csv`, `06_delta_rs_scan*.csv`, `06_cmb_chi2_scan2D.csv`
* Params : `06_cmb_params.json`

### 5.6 Chapitre 7 (perturbations scalaires)

* Params/méta : `07_params_perturbations.json`, `07_meta_perturbations.json`
* Matrices : `07_cs2_matrix.csv`, `07_delta_phi_matrix.csv` (`k,a,value`)
* Dérivées : `07_dcs2_dk.csv`, `07_ddelta_phi_dk.csv`
* Domaine/frontière : `07_perturbations_domain.csv`, `07_perturbations_boundary.csv`
* Invariants : `07_scalar_invariants.csv`
* Phase run : `07_phase_run.csv` : `k,a,cs2_raw,delta_phi_raw`

### 5.7 Chapitre 8 (couplage sombre)

* Params : `08_params_coupling.json`
* Scans : `08_chi2_scan2D.csv`, `08_chi2_total_vs_q0.csv`
* BAO/SN : `08_bao_data.csv`, `08_pantheon_data.csv`
* Modèles : `08_dv_theory_{z|q0star}.csv`, `08_mu_theory_{z|q0star}.csv`
* Jalons : `08_coupling_milestones.csv`

### 5.8 Chapitre 9 (phase GW)

* Référence : `09_phases_imrphenom.csv` (+ `.meta.json`)
* Modèle : `09_phases_mcgt.csv` : `f_Hz,phi_ref,phi_mcgt,phi_mcgt_raw,phi_mcgt_cal`
* Résidu : `09_phase_diff.csv` : `f_Hz,abs_dphi` (résidu principal)
* Métriques : `09_metrics_phase.json`
* Jalons : `09_comparison_milestones.csv` :
  `event,f_Hz,phi_ref_at_fpeak,phi_mcgt_at_fpeak,phi_mcgt_at_fpeak_raw,phi_mcgt_at_fpeak_cal,obs_phase,sigma_phase,epsilon_rel,classe,variant`
  (+ `09_comparison_milestones.meta.json`)

### 5.9 Chapitre 10 (Monte Carlo 8D)

* Config : `10_mc_config.json`
* Résultats : `10_mc_results.csv`, `10_mc_results.circ.csv`
* Top-k : `10_mc_best.json`, `10_mc_best_bootstrap.json`
* Évaluation jalons : `10_mc_milestones_eval.csv`

---

## 6) Calibration & résidu « principal » (chap. 9–10)

### 6.1 Calibration φ₀, t\_c

* Activée par défaut ; fenêtres : `initial_window_Hz=[20,300]`, `used_window_Hz=[30,250]`; pondération `1/f^2`.
* **Critère** : `p95_after < p95_before` (objectif *cible* : `p95_after ≤ 5 rad`).

### 6.2 Définition du résidu principal

Pour une série triée en fréquence `f_Hz` :

1. **unwrap** du Δφ,
2. estimation de `k = round(median( (phi_mcgt−phi_ref)/(2π) ))` sur **\[20,300] Hz**,
3. **résidu principal** :

$$
\left|((\phi_{\rm mcgt}-k\,2\pi-\phi_{\rm ref}+\pi)\bmod 2\pi)-\pi\right|
$$

4. Calcul des métriques (mean/median/p95/max) **exclusivement** sur **\[20,300] Hz**.

### 6.3 Correction polynomiale (optionnelle)

* Base `log10`, degré **5** par défaut ; documenter `basis`, `degree`, `fit_window_Hz`, `metrics_window_Hz`, `coeff_desc`.
* **Attention** au sur-ajustement hors fenêtre ; toujours valider par tracés.

---

## 7) Paramètres de référence (centralisés)

### 7.1 Cosmologie/CMB (chap. 6)

* `H0=67.36`, `ombh2=0.02237`, `omch2=0.12`, `tau=0.0544`, `mnu=0.06`, `As0=2.10e-9`, `ns0=0.9649`
* `ell_min=2`, `ell_max=3000`
* Lissage : `derivative_window=7`, `derivative_polyorder=3`

### 7.2 Spectre primordial (chap. 2)

* $P_R(k;\alpha)=A_s(\alpha)\,k^{n_s(\alpha)-1}$
* Constantes : `A_s0=2.10e-9`, `ns0=0.9649`; coefficients : `c1=0.10`, `c2=0.01`

### 7.3 Perturbations scalaires (chap. 7)

* `k∈[1e-4,10]` (log, `dlog=0.01`) ; `a∈[0.05,1.0]` (lin, `n_a=20`)
* `cs2_param=1.0`, `delta_phi_param=0.05`, `x_split=0.02`, `k0=0.1`, `alpha=0.5`

### 7.4 f(R) (chap. 3)

* *Ranges* et grandeurs selon fichiers `03_fR_stability_*.csv` (voir méta).
* Masse scalaire normalisée `m_s2_over_R0` rapportée systématiquement.

### 7.5 Monte Carlo 8D (chap. 10)

* Sobol : `scramble=true`, `seed=12345`, `n=5000`
* Bornes : `m1,m2∈[5,80]`, `q0star∈[-0.3,0.3]`, `alpha∈[-1,1]`, `phi0∈[-π,π]`, `tc∈[-0.01,0.01]`, `dist∈[50,2000]` (Mpc), `incl∈[0,π]`
* Fenêtre métrique : **\[20,300] Hz** ; variantes circulaires documentées.

---

## 8) Schémas & validation

### 8.1 Schémas JSON/CSV (exemples)

* `zz-schemas/mc_config_schema.json`
* `zz-schemas/mc_best_schema.json`
* `zz-schemas/metrics_phase_schema.json`
* `zz-schemas/mc_results_table_schema.json`
* `zz-schemas/comparison_milestones_table_schema.json` *(nom canonique ; alias FR pris en charge via rules)*
* `zz-schemas/meta_schema.json`, `zz-schemas/results_schema_examples.json`

### 8.2 Outils

* `zz-schemas/validate_json.py <schema> <instance.json>`
* `zz-schemas/validate_csv_table.py <schema> <table.csv>`
* `zz-manifests/diag_consistency.py --manifest zz-manifests/manifest_master.json [--fix ...]`

### 8.3 Règles de cohérence transverses

* `zz-schemas/consistency_rules.json` centralise : valeurs canoniques (H0, As0, ns0, fenêtres métriques, seuils), **aliases de chemins**, **correspondances de noms** (FR↔EN).
* Les scripts d’audit (ex. `diag_consistency.py`) doivent charger ces règles et **rapporter uniformément** (normalisation des chemins, renommages suggérés, fenêtres attendues, etc.).

---

## 9) QA & pipeline de contrôle

1. **JSON/CSV** : valider toutes les instances contre leurs schémas.
2. **Manifests** : vérifier présence/empreintes → `manifest_report.json`.
3. **Fenêtres & métriques** : confirmer `[20,300] Hz` et `p95` (chap. 9–10).
4. **Grilles** : `actual_n_points` vs `n_points` (tolérance ±2 %).
5. **Angles** : toujours en **radians** (clarifier `_circ`).
6. **Reproductibilité** : consigner `seed`, `n`, `git_hash`, `generated_at`.
7. **Figures** : tracer *avant/après* calibration et *k±1* (stab. résidu principal).
8. **Archives** : conserver preuves (PNG/logs) dans `zz-figures/chapter*/` et archives datées.

---

## 10) Homogénéisation linguistique

* **Fichiers & dossiers** : **anglais** (voir §1.1).
* **Sources LaTeX** (`.tex`) : noms **français** conservés (ex. `09_phase_ondes_grav_conceptuel.tex`).
* **Colonnes/variables** : notations scientifiques usuelles (anglais) : `A_s`, `n_s`, `k`, `ell`, `f_Hz`, etc.

---

## 11) Points d’attention

* **Invariant I3 (chap. 4)** : une ambiguïté d’expression a été signalée ; valider la définition retenue avant publication finale.
* **Échelle `p95` (chap. 10)** : harmoniser *radians* entre `10_mc_results*.csv` et `10_mc_best*.json` (linéaire vs circulaire) ; documenter toute conversion.
* **Poly degré 5** : surveiller le hors-fenêtre (overfit).
* **Aliases de chemins** : éviter les confusions `chapter09` vs `chapter9` ; s’appuyer sur `consistency_rules.json`.

---

## 12) Appendice — gabarit `.meta.json`

```json
{
  "generated_at": "2025-08-28T12:34:56Z",
  "git_hash": "abc1234",
  "config_used": "zz-configuration/mcgt-global-config.ini",
  "python": "3.12.3",
  "libs": { "numpy": "2.3.1", "pandas": "2.3.1", "lalsuite": "6.2.0" },
  "n_points": 232,
  "actual_n_points": 232,
  "grid": { "fmin_Hz": 10.0, "fmax_Hz": 2048.0, "dlog10": 0.01 },
  "checksum_sha256": {
    "zz-data/chapter09/09_phases_mcgt.csv": "…"
  },
  "files": [
    "zz-data/chapter09/09_phases_mcgt.csv",
    "zz-data/chapter09/09_phase_diff.csv"
  ],
  "manifest_entry": "zz-manifests/manifest_master.json#entries/…"
}
```

---

## 13) Références croisées (exemples usuels)

* **Chap. 9** : `09_metrics_phase.json` ↔ `09_phases_mcgt.csv` ↔ `09_comparison_milestones.csv`
* **Chap. 10** : `10_mc_config.json` → `10_mc_results*.csv` → `10_mc_best*.json` (option : `10_mc_milestones_eval.csv`)
* **Schémas** : `mc_config_schema.json`, `mc_results_table_schema.json`, `metrics_phase_schema.json`, `comparison_milestones_table_schema.json`
* **Manifests** : `manifest_master.json` (référence), `manifest_publication.json` (sélection publique), `manifest_report.json` (audit)

---

## 14) Sécurité / provenance

* Tous les artefacts publiés doivent être dans `manifest_master.json` avec **SHA-256** et **chemin relatif**.
* Les rapports d’audit (`diag_consistency.py`) sont conservés avec horodatage.
* Les dépendances et versions d’outils (section `libs`) doivent être renseignées dans chaque méta.

---

## 15) Exécution (extraits Makefile)

* QA rapide : `make qa`
* Validation JSON seule : `make validate-json`
* Validation CSV (tables) : `make validate-csv`
* Rapport manifest : `make manifests-md`
