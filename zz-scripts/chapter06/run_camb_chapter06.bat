@echo off
REM ------------------------------------------------------------------------------
REM Script: run_camb_chapitre6.bat
REM Usage: Executez ce script depuis la racine du projet pour générer le spectre CMB MCGT
REM ------------------------------------------------------------------------------

REM 1) Générer l’expansion plateau (H(z)/H0)
python zz-scripts/chapter06/generer_pdot_plateau_z.py

REM 2) Lancer CAMB pour produire les spectres ΛCDM et MCGT
camb zz-configuration\camb_plateau_exact.ini ^
    output_root=mcgt_spectre ^
    expansion_rate_file=zz-configuration\pdot_plateau_z.dat

REM 3) Lancer le pipeline Python complet (données & JSON)
REM    On passe maintenant --alpha et --q0star pour injecter la déformation MCGT
python zz-scripts/chapter06/generer_donnees_chapitre6.py --export-derivative --alpha 0.10 --q0star -0.005

REM 4) Générer les figures CMB
python zz-scripts/chapter06/tracer_fig01_schema_flux_donnees_cmb.py
python zz-scripts/chapter06/tracer_fig02_cls_lcdm_vs_mcgt.py
python zz-scripts/chapter06/tracer_fig03_delta_cls_rel.py
python zz-scripts/chapter06/tracer_fig04_carte_chaleur_delta_chi2.py
python zz-scripts/chapter06/tracer_fig05_carte_chaleur_delta_chi2.py

echo ------------------------------------------------------------------------------
echo Pipeline CMB Chapitre 6 termine.
echo ------------------------------------------------------------------------------
