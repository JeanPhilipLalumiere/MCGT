import sys
import pandas as pd
import numpy as np
import pathlib as p
import re

IMR = p.Path("assets/zz-data/09_dark_energy_cpl/09_phases_imrphenom.csv")
MCGT = p.Path("assets/zz-data/09_dark_energy_cpl/09_phases_mcgt.csv")
OUT = p.Path("zz-out/chapter09/fig02_input.csv")


def pick(df, candidates):
    lower = {c.lower(): c for c in df.columns}
    for names in candidates:
        for n in names:
            if n in lower:
                return lower[n]
    return None


def best_freq_col(df):
    cand = [
        ["f"],
        ["freq"],
        ["frequency_hz"],
        ["frequency"],
        ["f_hz"],
        ["nu"],
        ["nu_hz"],
    ]
    c = pick(df, cand)
    if c:
        return c
    # fallback: première num. monotone croissante
    nums = [c for c in df.columns if pd.api.types.is_numeric_dtype(df[c])]
    for c in nums:
        x = pd.to_numeric(df[c], errors="coerce").to_numpy()
        if np.all(np.isfinite(x)) and np.all(np.diff(x) > 0):
            return c
    return nums[0] if nums else None


def find_phi_col(df, priority_regexes, fallback_regex=r"phi|phase"):
    cols = list(df.columns)
    # 1) Priorités par regex (ordre donné)
    for rx in priority_regexes:
        r = re.compile(rx, re.I)
        for c in cols:
            if r.search(c):
                return c
    # 2) Sinon, toute colonne contenant phi/phase
    rfb = re.compile(fallback_regex, re.I)
    phi_like = [c for c in cols if rfb.search(c)]
    if phi_like:
        # prendre celle à plus grande variance (plus “informatif”)
        phi_like = sorted(
            phi_like,
            key=lambda c: pd.to_numeric(df[c], errors="coerce").std(skipna=True),
            reverse=True,
        )
        return phi_like[0]
    # 3) Ultime secours: meilleure colonne numérique (hors fréquence probable)
    freq_names = {"f", "freq", "frequency", "frequency_hz", "f_hz", "nu", "nu_hz"}
    numeric = [
        c
        for c in cols
        if pd.api.types.is_numeric_dtype(df[c]) and c.lower() not in freq_names
    ]
    if numeric:
        numeric = sorted(
            numeric,
            key=lambda c: pd.to_numeric(df[c], errors="coerce").std(skipna=True),
            reverse=True,
        )
        return numeric[0]
    return None


def load_csv(path):
    df = pd.read_csv(path)
    # opportuniste: convertir les strings numériques
    for c in df.columns:
        if df[c].dtype == object:
            df[c] = pd.to_numeric(df[c], errors="ignore")
    return df


if not IMR.exists() or not MCGT.exists():
    sys.exit("[ERREUR] Fichiers requis manquants: IMR/MCGT")

df_imr = load_csv(IMR)
df_mc = load_csv(MCGT)

# fréquence
f_imr = best_freq_col(df_imr)
f_mc = best_freq_col(df_mc)
if not f_imr or not f_mc:
    sys.exit("[ERREUR] Impossible d’identifier la colonne fréquence dans IMR/MCGT.")

# phi_ref côté IMR (priorité aux noms explicites)
phi_imr = find_phi_col(
    df_imr,
    priority_regexes=[
        r"^phi_?ref(_cal|_raw)?$",
        r"^phi_?imr$",
        r"ref.*phi",
        r"imr.*phi",
    ],
)
if not phi_imr:
    sys.exit("[ERREUR] Impossible d’identifier la colonne de phase IMR/ref dans IMR.")

# phi_active côté MCGT (couverture large des variantes)
phi_mc = find_phi_col(
    df_mc,
    priority_regexes=[
        r"^phi_?active$",
        r"^phi_?mcgt(_active|_cal)?$",
        r"^phi(_cal)?$",
        r"^phase(_mcgt|_active)?$",
        r"mcgt.*phi",
        r"active.*phi",
    ],
)
if not phi_mc:
    sys.exit(
        "Aucune colonne de phase MCGT détectée (essayé: phi_active/phi_mcgt/phi/phase...)."
    )

# alignement par fréquence (plus proche voisin)
fi = pd.to_numeric(df_imr[f_imr], errors="coerce").to_numpy()
fm = pd.to_numeric(df_mc[f_mc], errors="coerce").to_numpy()
pi = pd.to_numeric(df_imr[phi_imr], errors="coerce").to_numpy()
pm = pd.to_numeric(df_mc[phi_mc], errors="coerce").to_numpy()

fi_mask = np.isfinite(fi) & np.isfinite(pi)
fm_mask = np.isfinite(fm) & np.isfinite(pm)
fi, pi = fi[fi_mask], pi[fi_mask]
fm, pm = fm[fm_mask], pm[fm_mask]

if fi.size == 0 or fm.size == 0:
    sys.exit("[ERREUR] Séries vides après nettoyage.")

idx = np.searchsorted(fm, fi)
idx = np.clip(idx, 0, len(fm) - 1)
idx_minus = np.maximum(idx - 1, 0)
choose_minus = np.abs(fm[idx_minus] - fi) < np.abs(fm[idx] - fi)
idx = np.where(choose_minus, idx_minus, idx)
f_match = fm[idx]
ok = np.isfinite(f_match) & (
    np.abs(f_match - fi) <= np.maximum(1e-6, 1e-6 * np.maximum(1.0, fi))
)
fi, pi, pm = fi[ok], pi[ok], pm[idx][ok]

out = pd.DataFrame(
    {
        "f": fi.astype(float),
        "f_Hz": fi.astype(float),  # exigé par plot_fig02
        "phi_ref": pi.astype(float),
        "phi_active": pm.astype(float),
    }
)
out = out[
    np.isfinite(out["f"]) & np.isfinite(out["phi_ref"]) & np.isfinite(out["phi_active"])
]

OUT.parent.mkdir(parents=True, exist_ok=True)
out.to_csv(OUT, index=False)
print(
    f"[OK] fig02_input.csv → {OUT} (n={len(out)}) ; IMR({f_imr},{phi_imr}) vs MCGT({f_mc},{phi_mc})"
)
