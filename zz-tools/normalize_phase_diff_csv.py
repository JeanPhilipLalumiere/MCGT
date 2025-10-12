import sys, json, pandas as pd, pathlib as p, numpy as np

if len(sys.argv) < 3:
    print("Usage: normalize_phase_diff_csv.py <in.csv> <out.csv>", file=sys.stderr)
    sys.exit(2)

inp, outp = p.Path(sys.argv[1]), p.Path(sys.argv[2])
df = pd.read_csv(inp)

def pick(df, names):
    for n in names:
        if n in df.columns: return n
    return None

# 1) Chercher la fréquence dans des variantes courantes
F = pick(df, [
    "f","freq","frequency","frequency_Hz","Frequency_Hz","Frequency",
    "f_Hz","F_Hz","nu","nu_Hz"
])

# 2) Colonnes de phase (ref / active / résiduel)
REF = pick(df, ["phi_ref","phi_imr","phi_ref_cal","phi_ref_raw","phi_ref_model"])
ACT = pick(df, ["phi_active","phi_mcgt_cal","phi_mcgt","phi_model","phi_mcgt_active"])
RES = pick(df, ["dphi","phi_diff","delta_phi","phi_residual","residual_phi"])

# 3) Reconstruire f si manquant
f = None
if F is not None:
    f = pd.to_numeric(df[F], errors="coerce").to_numpy()
else:
    # 3a) Essayer via les métriques (grid_used)
    metrics = p.Path("zz-data/chapter09/09_metrics_phase.json")
    if metrics.exists():
        try:
            m = json.loads(metrics.read_text(encoding="utf-8"))
            gu = m.get("grid_used", {})
            fmin = float(gu.get("fmin_Hz", np.nan))
            fmax = float(gu.get("fmax_Hz", np.nan))
            npts = int(gu.get("n_points_used", 0))
            dlog10 = float(gu.get("dlog10", np.nan))
            if npts and np.isfinite(fmin) and np.isfinite(fmax) and fmin>0 and fmax>fmin:
                # Reconstruction log-uniforme par défaut
                f = np.logspace(np.log10(fmin), np.log10(fmax), npts)
                if len(f) != len(df):
                    # Si taille ne correspond pas exactement, on tronque/recale prudemment
                    n = min(len(f), len(df))
                    f = f[:n]
                    df = df.iloc[:n, :].copy()
                print(f"[INFO] f reconstruit depuis metrics: [{f[0]:.3f},{f[-1]:.3f}] n={len(f)}")
        except Exception as e:
            print(f"[WARN] Reconstruction via metrics échouée: {e}", file=sys.stderr)

    # 3b) Secours : IMR CSV
    if f is None:
        ref_csv = p.Path("zz-data/chapter09/09_phases_imrphenom.csv")
        if ref_csv.exists():
            dfref = pd.read_csv(ref_csv)
            Fref = pick(dfref, ["f","freq","frequency_Hz","Frequency_Hz","Frequency","f_Hz"])
            if Fref:
                f = pd.to_numeric(dfref[Fref], errors="coerce").to_numpy()
                if len(f) != len(df):
                    n = min(len(f), len(df))
                    f = f[:n]; df = df.iloc[:n, :].copy()
                print(f"[INFO] f récupéré depuis {ref_csv}: n={len(f)}")
        if f is None:
            sys.exit("Colonne fréquence absente et impossible à reconstruire (metrics/IMR).")

# 4) Construire la sortie normalisée
out = pd.DataFrame()
out["f"] = f.astype(float)

# Cas 1 : ref + active
if REF and ACT:
    out["phi_ref"] = pd.to_numeric(df[REF], errors="coerce")
    out["phi_active"] = pd.to_numeric(df[ACT], errors="coerce")

# Cas 2 : ref + résiduel
elif REF and RES:
    pr = pd.to_numeric(df[REF], errors="coerce")
    d  = pd.to_numeric(df[RES], errors="coerce")
    out["phi_ref"] = pr
    out["phi_active"] = pr + d

# Cas 3 : active + résiduel
elif ACT and RES:
    pa = pd.to_numeric(df[ACT], errors="coerce")
    d  = pd.to_numeric(df[RES], errors="coerce")
    out["phi_active"] = pa
    out["phi_ref"] = pa - d

# Cas 4 : dernier recours -> prendre deux colonnes "phi*"
else:
    phase_like = [c for c in df.columns if c.lower().startswith("phi")]
    if len(phase_like) >= 2:
        out["phi_ref"] = pd.to_numeric(df[phase_like[0]], errors="coerce")
        out["phi_active"] = pd.to_numeric(df[phase_like[1]], errors="coerce")
    else:
        sys.exit("Impossible de normaliser : colonnes phi_ref/phi_active/dphi manquantes.")

# 5) Nettoyage
mask = np.isfinite(out["f"]) & np.isfinite(out["phi_ref"]) & np.isfinite(out["phi_active"])
out = out[mask].copy()
outp.parent.mkdir(parents=True, exist_ok=True)
out.to_csv(outp, index=False)
print(f"[OK] Normalized CSV → {outp} (n={len(out)})")
