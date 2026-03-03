@echo off
REM ------------------------------------------------------------------------------
REM Script: run_camb_chapter6.bat
REM Usage: Executez ce script depuis la racine du projet pour générer le spectre CMB MCGT
REM ------------------------------------------------------------------------------

REM 1) Générer l’expansion plateau (H(z)/H0)
python scripts\06_early_growth_jwst\generate_pdot_plateau_vs_z.py

REM 2) Lancer CAMB pour produire les spectres ΛCDM et MCGT
camb 06-cmb-radiation\camb_plateau_exact.ini ^
    output_root=mcgt_spectrum ^
    expansion_rate_file=config\pdot_plateau_z.dat

REM 3) Lancer le pipeline Python complet (données & JSON)
REM    On passe maintenant --alpha et --q0star pour injecter la déformation MCGT
python scripts\06_early_growth_jwst\generate_data_chapter06.py --export-derivative --alpha 0.10 --q0star -0.005

REM 4) Générer les figures CMB
python scripts\06_early_growth_jwst\06_fig_01_spectrum.py
python scripts\06_early_growth_jwst\06_fig_02_growth_rate.py
python scripts\06_early_growth_jwst\06_fig_03_growth_factor.py
python scripts\06_early_growth_jwst\06_fig_05_delta_chi2_heatmap.py

echo ------------------------------------------------------------------------------
echo Pipeline CMB Chapter 6 termine.
echo ------------------------------------------------------------------------------
