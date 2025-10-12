# zz-tools/plot_fig02_from_input.py
#!/usr/bin/env python3
import argparse, pandas as pd, numpy as np, matplotlib.pyplot as plt
ap = argparse.ArgumentParser()
ap.add_argument("--csv", required=True)
ap.add_argument("--out", required=True)
ap.add_argument("--dpi", type=int, default=120)
args = ap.parse_args()

df = pd.read_csv(args.csv)
# Colonnes tolérées
fcol = next((c for c in ("f_Hz","f","freq","frequency","frequency_Hz","nu","nu_Hz") if c in df.columns), None)
if fcol is None: raise SystemExit("Aucune colonne fréquence détectée")
rcol = next((c for c in ("phi_ref","phi_imr","phi_ref_cal","phi_ref_raw","phi_ref_model") if c in df.columns), None)
acol = None
for c in ("phi_active","phi_mcgt","phi_mcgt_cal","phi_model","phi_mcgt_active"):
    if c in df.columns: acol = c; break
if rcol is None or acol is None: raise SystemExit("Colonnes phi_ref/phi_active manquantes")

f   = pd.to_numeric(df[fcol], errors="coerce").to_numpy()
ref = pd.to_numeric(df[rcol], errors="coerce").to_numpy()
act = pd.to_numeric(df[acol], errors="coerce").to_numpy()
m   = np.isfinite(f) & np.isfinite(ref) & np.isfinite(act)
f, ref, act = f[m], ref[m], act[m]

dphi = act - ref
# Rebranch simple par pas entier de 2π pour minimiser l'écart en 20–300 Hz
def rebranch(y):
    two_pi = 2*np.pi
    y0 = y.copy()
    # robust median-based cycle estimate
    k = np.round(np.median(y0[(f>=20)&(f<=300)]/two_pi))
    return y0 - k*two_pi
dphi_rb = rebranch(dphi)

# Stats (20–300)
sel = (f>=20)&(f<=300)
if np.any(sel):
    s = np.abs(dphi_rb[sel])
    mean = float(np.nanmean(s)); p95 = float(np.nanpercentile(s,95)); mx=float(np.nanmax(s))
    print(f"[INFO] Stats 20–300 Hz: mean={mean:.3f}  p95={p95:.3f}  max={mx:.3f}  (n={int(sel.sum())})")

plt.figure(figsize=(8,4.5))
plt.plot(f, dphi_rb, lw=1.2)
plt.xlabel("f [Hz]"); plt.ylabel("Δφ (active - ref) [rad]")
plt.title("Residual phase (fallback)")
plt.grid(True, alpha=0.3)
plt.gcf().subplots_adjust(left=0.1,right=0.98,bottom=0.15,top=0.9)
plt.savefig(args.out, dpi=args.dpi)
print(f"[OK] Fallback fig02 → {args.out}")
