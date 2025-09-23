#!/usr/bin/env python3
import os
import pandas as pd

# Directories (translated to English)
BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.abspath(os.path.join(BASE_DIR, "../../zz-data/chapter08"))

# 1) Load BAO from the final CSV
# Original: 08_donnees_bao.csv -> Translated: 08_bao_data.csv
df_bao = pd.read_csv(os.path.join(DATA_DIR, "08_bao_data.csv"))
df_bao = df_bao.rename(columns={'DV_obs': 'obs', 'sigma_DV': 'sigma_obs'})
df_bao['milestone'] = df_bao['z'].apply(lambda z: f"BAO_z={z:.3f}")
df_bao['category'] = df_bao.apply(
    lambda row: 'primary' if row.sigma_obs / row.obs <= 0.01 else 'order2',
    axis=1
)

# 2) Load Pantheon+ from the final CSV
# Original: 08_donnees_pantheon.csv -> Translated: 08_pantheon_data.csv
df_sn = pd.read_csv(os.path.join(DATA_DIR, "08_pantheon_data.csv"))
df_sn = df_sn.rename(columns={'mu_obs': 'obs', 'sigma_mu': 'sigma_obs'})
# Create labels SN0, SN1, ...
df_sn['milestone'] = df_sn.index.map(lambda i: f"SN{i}")
df_sn['category'] = df_sn.apply(
    lambda row: 'primary' if row.sigma_obs / row.obs <= 0.01 else 'order2',
    axis=1
)

# 3) Concatenate and keep columns in a consistent order
df_all = pd.concat([
    df_bao[['milestone', 'z', 'obs', 'sigma_obs', 'category']],
    df_sn[['milestone', 'z', 'obs', 'sigma_obs', 'category']]
], ignore_index=True)

# 4) Export the final CSV (translated name)
# Original: 08_jalons_couplage.csv -> Translated: 08_coupling_milestones.csv
out_csv = os.path.join(DATA_DIR, "08_coupling_milestones.csv")
df_all.to_csv(out_csv, index=False, encoding='utf-8')
print(f"✅ 08_coupling_milestones.csv generated: {out_csv}")
