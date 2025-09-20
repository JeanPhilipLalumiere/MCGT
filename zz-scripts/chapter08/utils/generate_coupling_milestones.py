#!/usr/bin/env python3
import os
import pandas as pd

# Répertoires
BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.abspath(os.path.join(BASE_DIR, "../../zz-data/chapter8"))

# 1) Charger BAO depuis le CSV final
df_bao = pd.read_csv(os.path.join(DATA_DIR, "08_donnees_bao.csv"))
df_bao = df_bao.rename(columns={"DV_obs": "obs", "sigma_DV": "sigma_obs"})
df_bao["jalon"] = df_bao["z"].apply(lambda z: f"BAO_z={z:.3f}")
df_bao["classe"] = df_bao.apply(
    lambda row: "primaire" if row.sigma_obs / row.obs <= 0.01 else "ordre2", axis=1
)

# 2) Charger Pantheon+ depuis le CSV final
df_sn = pd.read_csv(os.path.join(DATA_DIR, "08_donnees_pantheon.csv"))
df_sn = df_sn.rename(columns={"mu_obs": "obs", "sigma_mu": "sigma_obs"})
# Création du libellé SN0, SN1, …
df_sn["jalon"] = df_sn.index.map(lambda i: f"SN{i}")
df_sn["classe"] = df_sn.apply(
    lambda row: "primaire" if row.sigma_obs / row.obs <= 0.01 else "ordre2", axis=1
)

# 3) Concaténer et ordonner les colonnes
df_all = pd.concat(
    [
        df_bao[["jalon", "z", "obs", "sigma_obs", "classe"]],
        df_sn[["jalon", "z", "obs", "sigma_obs", "classe"]],
    ],
    ignore_index=True,
)

# 4) Exporter le CSV final
out_csv = os.path.join(DATA_DIR, "08_jalons_couplage.csv")
df_all.to_csv(out_csv, index=False, encoding="utf-8")
print(f"✅ 08_jalons_couplage.csv généré : {out_csv}")
