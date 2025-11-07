#!/usr/bin/env bash
set -euo pipefail

echo "[START] Patch & quick tests for chapter10"

ROOT_DIR="$(pwd)"
SCRIPTS_DIR="zz-scripts/chapter10"
DATA_DIR="zz-data/chapter10"
OUT_DIR="zz-out/chapter10"

mkdir -p "$SCRIPTS_DIR" "$DATA_DIR" "$OUT_DIR"

###############################################################################
# 0) Jeu de données factice pour tests rapides
###############################################################################
python3 - <<'PY'
import numpy as np, pandas as pd, os
os.makedirs("zz-data/chapter10", exist_ok=True)

rng = np.random.default_rng(123)
N = 1200
# Paramètres simulés
m1 = rng.uniform(5, 40, size=N)
m2 = rng.uniform(5, 40, size=N)
# p95 original et "recalc"
p95_orig = rng.normal(0.8, 0.15, size=N).clip(0, 3)
p95_recalc = p95_orig + rng.normal(0, 0.02, size=N)
# phases autour de 0, wrap pour tester dphi
phi_ref = (rng.normal(0.0, 1.0, size=N) + np.pi) % (2*np.pi) - np.pi
phi_mcgt = (phi_ref + rng.normal(0.0, 0.25, size=N) + np.pi) % (2*np.pi) - np.pi

df = pd.DataFrame({
    "m1": m1, "m2": m2,
    "p95_20_300": p95_orig,
    "p95_20_300_recalc": p95_recalc,
    "phi_ref_fpeak": phi_ref,
    "phi_mcgt_fpeak": phi_mcgt
})
df.to_csv("zz-data/chapter10/dummy_results.csv", index=False)
print("[DATA] Wrote zz-data/chapter10/dummy_results.csv with", len(df), "rows")
PY

###############################################################################
# 1) plot_fig01_iso_p95_maps.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig01_iso_p95_maps.py
#!/usr/bin/env python3
"""
plot_fig01_iso_p95_maps.py
Carte iso-valeurs d'un p95 (ou métrique équivalente) sur (m1, m2) à partir d'un CSV.
- Détection robuste de la colonne p95 (ou --p95-col)
- Tricontours + scatter des échantillons
"""
from __future__ import annotations
import argparse, sys, warnings
import numpy as np, pandas as pd, matplotlib.pyplot as plt, matplotlib.tri as tri
from matplotlib import colors
def detect_p95_column(df: pd.DataFrame, hint: str | None):
    if hint and hint in df.columns: return hint
    for c in ["p95_20_300_recalc","p95_20_300_circ","p95_20_300","p95_circ","p95_recalc","p95"]:
        if c in df.columns: return c
    for c in df.columns:
        if "p95" in c.lower(): return c
    raise KeyError("Aucune colonne 'p95' détectée dans le fichier results.")
def read_and_validate(path, m1_col, m2_col, p95_col):
    try: df = pd.read_csv(path)
    except Exception as e: raise SystemExit(f"Erreur lecture CSV '{path}': {e}")
    for col in (m1_col, m2_col, p95_col):
        if col not in df.columns: raise KeyError(f"Colonne attendue absente: {col}")
    df = df[[m1_col, m2_col, p95_col]].dropna().astype(float)
    if df.shape[0] == 0: raise ValueError("Aucune donnée valide après suppression des NaN.")
    return df
def make_triangulation_and_mask(x, y):
    triang = tri.Triangulation(x, y)
    try:
        tris = triang.triangles
        x1, x2, x3 = x[tris[:,0]], x[tris[:,1]], x[tris[:,2]]
        y1, y2, y3 = y[tris[:,0]], y[tris[:,1]], y[tris[:,2]]
        areas = 0.5 * np.abs((x2-x1)*(y3-y1) - (x3-x1)*(y2-y1))
        triang.set_mask(areas <= 0.0)
    except Exception: pass
    return triang
def main():
    ap = argparse.ArgumentParser(description="Carte iso de p95 (m1 vs m2)")
    ap.add_argument("--results", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--p95-col", default=None)
    ap.add_argument("--m1-col", default="m1"); ap.add_argument("--m2-col", default="m2")
    ap.add_argument("--levels", type=int, default=12)
    ap.add_argument("--no-clip", action="store_true")
    ap.add_argument("--cmap", default="viridis")
    ap.add_argument("--dpi", type=int, default=150)
    ap.add_argument("--title", default="Carte iso de p95 (m1 vs m2)")
    args = ap.parse_args()
    try: df_all = pd.read_csv(args.results)
    except Exception as e: print(f"[ERROR] Cannot read '{args.results}': {e}", file=sys.stderr); sys.exit(2)
    try: p95_col = detect_p95_column(df_all, args.p95_col)
    except KeyError as e: print(f"[ERROR] {e}", file=sys.stderr); sys.exit(2)
    try: df = read_and_validate(args.results, args.m1_col, args.m2_col, p95_col)
    except Exception as e: print(f"[ERROR] {e}", file=sys.stderr); sys.exit(2)
    x, y, z = df[args.m1_col].values, df[args.m2_col].values, df[p95_col].values
    triang = make_triangulation_and_mask(x, y)
    zmin, zmax = float(np.nanmin(z)), float(np.nanmax(z))
    if zmax - zmin < 1e-8: zmax = zmin + 1e-6
    levels = np.linspace(zmin, zmax, args.levels)
    vmin, vmax, clipped = zmin, zmax, False
    if not args.no_clip:
        try: p_lo, p_hi = np.percentile(z, [0.1, 99.9])
        except Exception: p_lo, p_hi = zmin, zmax
        if p_hi - p_lo > 1e-8 and (p_lo > zmin or p_hi < zmax):
            vmin, vmax, clipped = float(p_lo), float(p_hi), True
            warnings.warn(f"Clipping [{vmin:.4g}, {vmax:.4g}] (0.1%–99.9%).")
    norm = colors.Normalize(vmin=vmin, vmax=vmax, clip=True)
    plt.style.use("classic")
    fig, ax = plt.subplots(figsize=(10, 8))
    cf = ax.tricontourf(triang, z, levels=levels, cmap=args.cmap, alpha=0.95, norm=norm)
    ax.tricontour(triang, z, levels=levels, colors="k", linewidths=0.45, alpha=0.5)
    ax.scatter(x, y, c="k", s=3, alpha=0.5, edgecolors="none", label="échantillons", zorder=5)
    cbar = fig.colorbar(cf, ax=ax, shrink=0.8); cbar.set_label(f"{p95_col} [rad]")
    ax.set_xlabel(args.m1_col); ax.set_ylabel(args.m2_col); ax.set_title(args.title, fontsize=15)
    xmin, xmax = float(np.min(x)), float(np.max(x)); ymin, ymax = float(np.min(y)), float(np.max(y))
    xpad = 0.02 * (xmax - xmin) if xmax > xmin else 0.5; ypad = 0.02 * (ymax - ymin) if ymax > ymin else 0.5
    ax.set_xlim(xmin - xpad, xmax + xpad); ax.set_ylim(ymin - ypad, ymax + ypad)
    leg = ax.legend(loc="upper right", frameon=True, fontsize=9); leg.set_zorder(20)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore"); plt.tight_layout()
    try:
        fig.savefig(args.out, dpi=args.dpi); print(f"Wrote: {args.out}")
        if clipped: print("Note: color scaling clipped. Use --no-clip to disable.")
    except Exception as e:
        print(f"[ERROR] cannot write '{args.out}': {e}", file=sys.stderr); sys.exit(2)
if __name__ == "__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig01_iso_p95_maps.py

###############################################################################
# 2) plot_fig02_scatter_phi_at_fpeak.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py
#!/usr/bin/env python3
from __future__ import annotations
import argparse, numpy as np, pandas as pd, matplotlib.pyplot as plt
TWOPI = 2.0 * np.pi
def wrap_pi(x): return (x + np.pi) % TWOPI - np.pi
def circ_diff(a,b): return wrap_pi(b - a)
def circ_mean_rad(ang): return float(np.angle(np.mean(np.exp(1j*ang))))
def circ_std_rad(ang):
    R = np.abs(np.mean(np.exp(1j*ang))); return float(np.sqrt(max(0.0, -2.0*np.log(max(R,1e-12)))))
def bootstrap_circ_mean_ci(angles,B=1000,seed=12345):
    n=len(angles); 
    if n==0 or B<=0: th=circ_mean_rad(angles); return th, th, th
    rng=np.random.default_rng(seed); theta_hat=circ_mean_rad(angles)
    deltas=np.empty(B)
    for b in range(B):
        idx=rng.integers(0,n,size=n); th_b=circ_mean_rad(angles[idx]); deltas[b]=wrap_pi(th_b-theta_hat)
    lo,hi=np.percentile(deltas,[2.5,97.5]); 
    return float(theta_hat), float(wrap_pi(theta_hat+lo)), float(wrap_pi(theta_hat+hi))
def detect_column(df, hint, cands):
    if hint and hint in df.columns: return hint
    for c in cands:
        if c in df.columns: return c
    low=[c.lower() for c in df.columns]
    for cand in cands:
        if cand.lower() in low: return df.columns[low.index(cand.lower())]
    raise KeyError(f"Colonne manquante parmi: {cands}")
def main():
    p=argparse.ArgumentParser(description="Scatter φ_ref(f_peak) vs φ_MCGT(f_peak)")
    p.add_argument("--results", required=True); p.add_argument("--out", required=True)
    p.add_argument("--x-col", default=None); p.add_argument("--y-col", default=None)
    p.add_argument("--group-col", default=None)
    p.add_argument("--title", default="φ_ref(f_peak) vs φ_MCGT(f_peak)")
    p.add_argument("--dpi", type=int, default=300)
    p.add_argument("--alpha", type=float, default=0.7); p.add_argument("--point-size", type=float, default=8.0)
    p.add_argument("--cmap", default="viridis"); p.add_argument("--with-hexbin", action="store_true")
    p.add_argument("--hexbin-gridsize", type=int, default=40); p.add_argument("--hexbin-alpha", type=float, default=0.35)
    p.add_argument("--clip-pi", action="store_true"); p.add_argument("--pi-ticks", action="store_true")
    p.add_argument("--p95-ref", type=float, default=float(np.pi/4))
    p.add_argument("--annotate-top-k", type=int, default=0)
    p.add_argument("--boot-ci", type=int, default=200); p.add_argument("--seed", type=int, default=12345)
    args=p.parse_args()
    df=pd.read_csv(args.results)
    xcol=detect_column(df,args.x_col,["phi_ref_fpeak","phi_ref","phi_ref_f_peak","phi_ref_at_fpeak","phi_reference"])
    ycol=detect_column(df,args.y_col,["phi_mcgt_fpeak","phi_mcgt","phi_mcg","phi_mcg_at_fpeak","phi_MCGT"])
    sub=df[[xcol,ycol]].dropna().astype(float).copy(); x=sub[xcol].values; y=sub[ycol].values
    dphi=circ_diff(x,y); abs_d=np.abs(dphi); N=len(abs_d)
    mean_abs=float(np.mean(abs_d)); median_abs=float(np.median(abs_d)); p95_abs=float(np.percentile(abs_d,95))
    max_abs=float(np.max(abs_d)); frac_below=float(np.mean(abs_d<args.p95_ref))
    cmean_hat, ci_lo, ci_hi=bootstrap_circ_mean_ci(dphi, B=args.boot_ci, seed=args.seed)
    half_arc=0.5*float(np.abs(((ci_hi-ci_lo)+np.pi)%(2*np.pi)-np.pi))
    plt.style.use("classic"); fig, ax=plt.subplots(figsize=(8,8))
    if args.with_hexbin:
        ax.hexbin(x,y,gridsize=args.hexbin_gridsize,mincnt=1,cmap="Greys",alpha=args.hexbin_alpha,linewidths=0,zorder=0)
    sc=ax.scatter(x,y,c=abs_d,s=args.point_size,alpha=args.alpha,cmap=args.cmap,edgecolor="none",zorder=1)
    xmin,xmax=np.min(x),np.max(x); ymin,ymax=np.min(y),np.max(y)
    if args.clip_pi: ax.set_xlim(-np.pi,np.pi); ax.set_ylim(-np.pi,np.pi)
    else:
        pad_x=0.03*(xmax-xmin) if xmax>xmin else 0.1; pad_y=0.03*(ymax-ymin) if ymax>ymin else 0.1
        ax.set_xlim(xmin-pad_x,xmax+pad_x); ax.set_ylim(ymin-pad_y,ymax+pad_y)
    ax.set_aspect("equal", adjustable="box"); lo=min(ax.get_xlim()[0],ax.get_ylim()[0]); hi=max(ax.get_xlim()[1],ax.get_ylim()[1])
    ax.plot([lo,hi],[lo,hi],color="gray",linestyle="--",lw=1.2,zorder=2)
    ax.set_xlabel(f"{xcol} [rad]"); ax.set_ylabel(f"{ycol} [rad]"); ax.set_title(args.title,fontsize=15)
    cbar=fig.colorbar(sc,ax=ax); cbar.set_label(r"$|\Delta\phi|$ [rad]")
    if args.pi_ticks:
        ticks=[0.0,np.pi/4,np.pi/2,3*np.pi/4,np.pi]; cbar.set_ticks(ticks); cbar.set_ticklabels(["0", r"$\pi/4$", r"$\pi/2$", r"$3\pi/4$", r"$\pi$"])
    stat_lines=[f"N = {N}",f"|Δφ| mean = {mean_abs:.3f}",f"median = {median_abs:.3f}",f"p95 = {p95_abs:.3f}",
               f"max = {max_abs:.3f}",f"|Δφ| < {args.p95_ref:.4f} : {100*frac_below:.2f}%",
               f"circ-mean(Δφ) = {cmean_hat:.3f} rad",f"95% CI ≈ {cmean_hat:.3f} ± {half_arc:.3f} rad"]
    ax.text(0.02,0.98,"\n".join(stat_lines),transform=ax.transAxes,fontsize=9,va="top",ha="left",
            bbox=dict(boxstyle="round",fc="white",ec="black",lw=1,alpha=0.95),zorder=5)
    fig.text(0.5,0.02,r"$\Delta\phi$ circulaire (b − a mod $2\pi \rightarrow [-\pi,\pi)$).",ha="center",fontsize=9)
    plt.tight_layout(rect=[0,0.04,1,0.98]); fig.savefig(args.out,dpi=args.dpi); print(f"Wrote: {args.out}")
if __name__=="__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py

###############################################################################
# 3) plot_fig03_convergence_p95_vs_n.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py
#!/usr/bin/env python3
from __future__ import annotations
import argparse, numpy as np, pandas as pd, matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes
def detect_p95_column(df, hint):
    if hint and hint in df.columns: return hint
    for c in ["p95_20_300_recalc","p95_20_300_circ","p95_20_300","p95_circ","p95_recalc","p95"]:
        if c in df.columns: return c
    for c in df.columns:
        if "p95" in c.lower(): return c
    raise KeyError("Aucune colonne 'p95' détectée.")
def trimmed_mean(arr, alpha):
    if alpha <= 0: return float(np.mean(arr))
    n=len(arr); k=int(np.floor(alpha*n))
    if 2*k >= n: return float(np.mean(arr))
    a=np.sort(arr); return float(np.mean(a[k:n-k]))
def compute_bootstrap_convergence(p95, N_list, B, seed, trim_alpha):
    rng=np.random.default_rng(seed)
    out=[]
    for N in N_list:
        N=int(N)
        ests_mean=np.empty(B); ests_median=np.empty(B); ests_tmean=np.empty(B)
        for b in range(B):
            samp=rng.choice(p95,size=N,replace=True)
            ests_mean[b]=np.mean(samp); ests_median[b]=np.median(samp); ests_tmean[b]=trimmed_mean(samp,trim_alpha)
        def pct(a): return np.percentile(a,[2.5,97.5])
        out.append((ests_mean.mean(),*pct(ests_mean),ests_median.mean(),*pct(ests_median),ests_tmean.mean(),*pct(ests_tmean)))
    return tuple(np.array(x) for x in zip(*out))
def main():
    p=argparse.ArgumentParser(description="Convergence p95 vs N (bootstrap)")
    p.add_argument("--results", required=True); p.add_argument("--out", required=True)
    p.add_argument("--p95-col", default=None); p.add_argument("--B", type=int, default=400)
    p.add_argument("--npoints", type=int, default=14); p.add_argument("--seed", type=int, default=12345)
    p.add_argument("--dpi", type=int, default=150); p.add_argument("--trim", type=float, default=0.1)
    p.add_argument("--zoom-w", type=float, default=0.14); p.add_argument("--zoom-h", type=float, default=0.11)
    p.add_argument("--zoom-center-n", type=int, default=None)
    args=p.parse_args()
    df=pd.read_csv(args.results); p95_col=detect_p95_column(df,args.p95_col)
    p95=df[p95_col].dropna().astype(float).values; M=len(p95)
    if M==0: raise SystemExit("Aucun p95 disponible.")
    minN=max(10,int(max(10,M*0.01))); N_list=np.unique(np.linspace(minN,M,args.npoints,dtype=int))
    if N_list[-1]!=M: N_list=np.append(N_list,M)
    ref_mean=float(np.mean(p95))
    (mean_est, mean_low, mean_high, median_est, median_low, median_high, tmean_est, tmean_low, tmean_high) = \
        compute_bootstrap_convergence(p95,N_list,args.B,args.seed,args.trim)
    final_i=np.where(N_list==M)[0][0] if (N_list==M).any() else -1
    final_mean, final_mean_ci=(mean_est[final_i], (mean_low[final_i], mean_high[final_i]))
    plt.style.use("classic"); fig, ax=plt.subplots(figsize=(14,6))
    ax.fill_between(N_list,mean_low,mean_high,color="tab:blue",alpha=0.18,label="IC 95% (mean)")
    ax.plot(N_list,mean_est,color="tab:blue",lw=2.0,label="Estimateur (mean)")
    ax.plot(N_list,median_est,color="tab:orange",lw=1.6,ls="--",label="Estimateur (median)")
    ax.plot(N_list,tmean_est,color="tab:green",lw=1.6,ls="-.",label=f"Trimmed mean (α={args.trim:.2f})")
    ax.axhline(ref_mean,color="crimson",lw=2,label=f"Réf mean @ N={M}")
    ax.set_xlim(0,M); ax.set_xlabel("Taille d'échantillon N"); ax.set_ylabel(f"{p95_col} [rad]")
    ax.set_title(f"Convergence de l'estimation de {p95_col}",fontsize=15)
    ax.legend(loc="lower right",frameon=True,fontsize=10).set_zorder(5)
    base_w, base_h=args.zoom_w, args.zoom_h; inset_w, inset_h=base_w*1.5, base_h*2.3
    center_n=args.zoom_center_n if args.zoom_center_n is not None else int(M*0.5)
    xin0, xin1=max(0,center_n-int(max(10,M*0.25))//2), min(M,center_n+int(max(10,M*0.25))//2)
    sel=(N_list>=xin0)&(N_list<=xin1); 
    if np.sum(sel)==0:
        sel=slice(len(N_list)//3,2*len(N_list)//3); ylo,yhi=np.min(mean_low[sel]),np.max(mean_high[sel])
    else:
        ylo,yhi=float(np.nanmin(mean_low[sel])),float(np.nanmax(mean_high[sel]))
    ypad=0.02*(yhi-ylo) if (yhi-ylo)>0 else 0.005; yin0,yin1=ylo-ypad,yhi+ypad
    from mpl_toolkits.axes_grid1.inset_locator import inset_axes
    inset_ax=inset_axes(ax,width=f"{inset_w*100}%",height=f"{inset_h*100}%",
                        bbox_to_anchor=(0.62-inset_w/2.0,0.18,inset_w,inset_h),
                        bbox_transform=fig.transFigure,loc="lower left",borderpad=1)
    sel_idx=(N_list>=xin0)&(N_list<=xin1)
    inset_ax.fill_between(N_list[sel_idx],mean_low[sel_idx],mean_high[sel_idx],color="tab:blue",alpha=0.18)
    inset_ax.plot(N_list[sel_idx],mean_est[sel_idx],color="tab:blue",lw=1.5)
    inset_ax.plot(N_list[sel_idx],median_est[sel_idx],color="tab:orange",lw=1.2,ls="--")
    inset_ax.plot(N_list[sel_idx],tmean_est[sel_idx],color="tab:green",lw=1.2,ls="-.")
    inset_ax.axhline(ref_mean,color="crimson",lw=1.0,ls="--")
    inset_ax.set_xlim(xin0,xin1); inset_ax.set_ylim(yin0,yin1); inset_ax.set_title("zoom (mean)",fontsize=10)
    inset_ax.tick_params(axis="both",which="major",labelsize=8); inset_ax.grid(False)
    stat_lines=[f"N = {M}",f"mean = {final_mean:.3f} (95% CI [{final_mean_ci[0]:.3f}, {final_mean_ci[1]:.3f}])",
                f"bootstrap = percentile, B = {args.B}, seed = {args.seed}"]
    ax.text(0.98,0.28,"\n".join(stat_lines),transform=ax.transAxes,fontsize=9,va="bottom",ha="right",
            bbox=dict(boxstyle="round",fc="white",ec="black",lw=1,alpha=0.95),zorder=20)
    fig.text(0.5,0.02,f"Bootstrap (B={args.B}, percentile). Estimateurs : mean, median, trimmed mean.",ha="center",fontsize=9)
    plt.tight_layout(rect=[0,0.05,1,0.97]); fig.savefig(args.out,dpi=args.dpi); print(f"Wrote: {args.out}")
if __name__=="__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py

###############################################################################
# 4) plot_fig03b_bootstrap_coverage_vs_n.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py
#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, time, numpy as np, pandas as pd, matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes
def detect_p95_column(df, hint):
    if hint and hint in df.columns: return hint
    for c in ["p95_20_300_recalc","p95_20_300_circ","p95_20_300","p95_circ","p95_recalc","p95"]:
        if c in df.columns: return c
    for c in df.columns:
        if "p95" in c.lower(): return c
    raise KeyError("Aucune colonne p95 détectée (utiliser --p95-col).")
def wilson_err95(p, n):
    if n<=0: return 0.0,0.0
    z=1.959963984540054; denom=1.0+(z*z)/n; center=(p+(z*z)/(2*n))/denom
    half=(z/denom)*np.sqrt((p*(1-p)/n)+(z*z)/(4*n*n))
    lo=max(0.0, center-half); hi=min(1.0, center+half); return (p-lo, hi-p)
def bootstrap_percentile_ci(vals, B, rng, alpha=0.05):
    n=len(vals); boots=np.empty(B)
    for b in range(B):
        samp=rng.choice(vals,size=n,replace=True); boots[b]=float(np.mean(samp))
    lo=float(np.percentile(boots,100*(alpha/2))); hi=float(np.percentile(boots,100*(1-alpha/2))); return lo, hi
def circ_mean_rad(angles): return float(np.angle(np.mean(np.exp(1j*angles))))
def main():
    p=argparse.ArgumentParser(description="Couverture bootstrap percentile vs N")
    p.add_argument("--results", required=True); p.add_argument("--out", required=True)
    p.add_argument("--p95-col", default=None); p.add_argument("--outer", type=int, default=400)
    p.add_argument("--inner", type=int, default=800); p.add_argument("--M", type=int, default=None)
    p.add_argument("--alpha", type=float, default=0.05); p.add_argument("--npoints", type=int, default=8)
    p.add_argument("--minN", type=int, default=40); p.add_argument("--seed", type=int, default=12345)
    p.add_argument("--dpi", type=int, default=200)
    p.add_argument("--ymin-coverage", type=float, default=None); p.add_argument("--ymax-coverage", type=float, default=None)
    p.add_argument("--title-left", type=str, default="Couverture empirique (IC 95%)")
    p.add_argument("--title-right", type=str, default="Largeur moyenne de l’IC 95%")
    p.add_argument("--angular", action="store_true")
    p.add_argument("--hires2000", action="store_true")
    p.add_argument("--make-sensitivity", action="store_true")
    p.add_argument("--sens-mode", choices=["outer","inner"], default="outer")
    p.add_argument("--sens-N", type=int, default=None)
    p.add_argument("--sens-B-list", type=str, default="200,400,800,1600")
    args=p.parse_args()
    df=pd.read_csv(args.results); p95_col=detect_p95_column(df,args.p95_col)
    vals_all=df[p95_col].dropna().astype(float).values; Mtot=len(vals_all)
    if Mtot==0: raise SystemExit("Aucune donnée p95.")
    if args.hires2000:
        args.outer,args.inner=2000,2000
        if args.M is None: args.M=2000
        print("[INFO] Mode haute précision: outer=2000, inner=2000")
    minN=max(10,int(args.minN))
    N_list=np.unique(np.linspace(minN,Mtot,args.npoints,dtype=int))
    if N_list[-1]!=Mtot: N_list=np.append(N_list,Mtot)
    outer_for_cov=int(args.M) if args.M is not None else int(args.outer)
    rng=np.random.default_rng(args.seed)
    ref_value_lin=float(np.mean(vals_all))
    results=[]
    for N in N_list:
        hits=0; widths=np.empty(outer_for_cov)
        for b in range(outer_for_cov):
            samp=rng.choice(vals_all,size=int(N),replace=True)
            lo,hi=bootstrap_percentile_ci(samp,args.inner,rng,alpha=args.alpha)
            widths[b]=hi-lo
            if (ref_value_lin>=lo) and (ref_value_lin<=hi): hits+=1
        p_hat=hits/outer_for_cov; e_lo,e_hi=wilson_err95(p_hat,outer_for_cov)
        results.append(dict(N=int(N),coverage=float(p_hat),coverage_err95_low=float(e_lo),
                            coverage_err95_high=float(e_hi),width_mean=float(np.mean(widths)),
                            hits=int(hits),method="percentile"))
        print(f"[COV] N={N:5d} coverage={p_hat:.3f} width_mean={np.mean(widths):.5f}")
    import matplotlib.pyplot as plt
    plt.style.use("classic"); fig=plt.figure(figsize=(15,6))
    gs=fig.add_gridspec(1,2,width_ratios=[5,3],wspace=0.25)
    ax1=fig.add_subplot(gs[0,0]); ax2=fig.add_subplot(gs[0,1])
    xN=[r["N"] for r in results]; yC=[r["coverage"] for r in results]
    yerr_low=[r["coverage_err95_low"] for r in results]; yerr_high=[r["coverage_err95_high"] for r in results]
    ax1.errorbar(xN,yC,yerr=[yerr_low,yerr_high],fmt="o-",lw=1.6,ms=6,color="tab:blue",ecolor="tab:blue",elinewidth=1.0,capsize=3,label="Couverture empirique")
    ax1.axhline(1-args.alpha,color="crimson",ls="--",lw=1.5,label=f"Niveau nominal {int((1-args.alpha)*100)}%")
    ax1.set_xlabel("Taille d'échantillon N"); ax1.set_ylabel("Couverture (IC contient la référence)"); ax1.set_title(args.title_left)
    if (args.ymin_coverage is not None) or (args.ymax_coverage is not None):
        ymin=args.ymin_coverage if args.ymin_coverage is not None else ax1.get_ylim()[0]
        ymax=args.ymax_coverage if args.ymax_coverage is not None else ax1.get_ylim()[1]; ax1.set_ylim(ymin,ymax)
    ax1.legend(loc="lower right",frameon=True)
    txt=(f"N = {Mtot}\nmean(ref) = {ref_value_lin:0.3f} rad\nouter B = {outer_for_cov}, inner B = {args.inner}\nseed = {args.seed}\nIC = percentile")
    ax1.text(0.02,0.97,txt,transform=ax1.transAxes,va="top",ha="left",bbox=dict(boxstyle="round",fc="white",ec="black",alpha=0.95))
    ax2.plot(xN,[r["width_mean"] for r in results],"-",lw=2.0,color="tab:green")
    ax2.set_xlabel("Taille d'échantillon N"); ax2.set_ylabel("Largeur moyenne de l'IC 95% [rad]"); ax2.set_title(args.title_right)
    fig.subplots_adjust(left=0.08,right=0.98,top=0.92,bottom=0.18,wspace=0.25)
    foot=(f"Bootstrap imbriqué: outer={outer_for_cov}, inner={args.inner}. Référence = mean({Mtot}) = {ref_value_lin:0.3f} rad. Seed={args.seed}.")
    fig.text(0.5,0.012,foot,ha="center",fontsize=10)
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    fig.savefig(args.out,dpi=args.dpi); print(f"[OK] Figure écrite: {args.out}")
    manifest_path=os.path.splitext(args.out)[0]+".manifest.json"
    manifest={"script":"plot_fig03b_bootstrap_coverage_vs_n.py","generated_at":time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "inputs":{"results":args.results,"p95_col":p95_col},
              "params":{"outer":int(outer_for_cov),"inner":int(args.inner),"alpha":float(args.alpha),
                        "seed":int(args.seed),"minN":int(args.minN),"npoints":int(args.npoints),
                        "ymin_coverage":None if args.ymin_coverage is None else float(args.ymin_coverage),
                        "ymax_coverage":None if args.ymax_coverage is None else float(args.ymax_coverage)},
              "ref_value_linear_rad":float(ref_value_lin),"ref_value_circular_rad":None,
              "N_list":[int(x) for x in np.asarray(N_list).tolist()],
              "results":results,"figure_path":args.out}
    with open(manifest_path,"w",encoding="utf-8") as f: json.dump(manifest,f,indent=2)
    print(f"[OK] Manifest écrit: {manifest_path}")
if __name__=="__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py

###############################################################################
# 5) plot_fig04_scatter_p95_recalc_vs_orig.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py
#!/usr/bin/env python3
from __future__ import annotations
import argparse, numpy as np, pandas as pd, matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes, mark_inset
def detect_column(df, hint, candidates):
    if hint and hint in df.columns: return hint
    for c in candidates:
        if c and c in df.columns: return c
    low=[c.lower() for c in df.columns]
    for cand in candidates:
        if cand and cand.lower() in low: return df.columns[low.index(cand.lower())]
    raise KeyError(f"Aucune colonne trouvée parmi : {candidates} (hint={hint})")
def main():
    p=argparse.ArgumentParser(description="Scatter p95_recalc vs p95_orig")
    p.add_argument("--results", required=True); p.add_argument("--out", required=True)
    p.add_argument("--orig-col", default="p95_20_300"); p.add_argument("--recalc-col", default="p95_20_300_recalc")
    p.add_argument("--title", default="p95 (recalc) vs p95 (orig)"); p.add_argument("--dpi", type=int, default=300)
    p.add_argument("--point-size", type=float, default=8.0); p.add_argument("--alpha", type=float, default=0.7)
    p.add_argument("--cmap", default="viridis"); p.add_argument("--change-eps", type=float, default=1e-9)
    p.add_argument("--with-zoom", action="store_true"); p.add_argument("--zoom-center-x", type=float, default=None)
    p.add_argument("--zoom-center-y", type=float, default=None); p.add_argument("--zoom-w", type=float, default=0.45)
    p.add_argument("--zoom-h", type=float, default=0.10); p.add_argument("--hist-x", type=float, default=0.60)
    p.add_argument("--hist-y", type=float, default=0.18); p.add_argument("--hist-scale", type=float, default=1.0)
    p.add_argument("--bins", type=int, default=50)
    args=p.parse_args()
    df=pd.read_csv(args.results)
    orig_col=detect_column(df,args.orig_col,[args.orig_col,"p95_20_300","p95"])
    recalc_col=detect_column(df,args.recalc_col,[args.recalc_col,"p95_20_300_recalc","p95_recalc"])
    sub=df[[orig_col,recalc_col]].dropna().astype(float).copy()
    x=sub[orig_col].values; y=sub[recalc_col].values
    if x.size==0: raise SystemExit("Aucun point non-NA trouvé.")
    delta=y-x; abs_delta=np.abs(delta); N=len(x)
    mean_x,mean_y=float(np.mean(x)),float(np.mean(y))
    mean_delta, med_delta=float(np.mean(delta)), float(np.median(delta))
    std_delta=float(np.std(delta,ddof=0))
    p95_abs, max_abs=float(np.percentile(abs_delta,95)), float(np.max(abs_delta))
    n_changed=int(np.sum(abs_delta>args.change_eps)); frac_changed=100.0*n_changed/N
    plt.style.use("classic"); fig, ax=plt.subplots(figsize=(10,10))
    vmax=float(np.percentile(abs_delta,99.9)) if abs_delta.size else 1.0
    if vmax<=0.0: vmax=float(np.max(abs_delta)) if abs_delta.size else 1.0
    if vmax<=0.0: vmax=1.0
    sc=ax.scatter(x,y,c=abs_delta,s=args.point_size,alpha=args.alpha,cmap=args.cmap,edgecolor="none",vmin=0.0,vmax=vmax,zorder=2)
    lo=min(np.min(x),np.min(y)); hi=max(np.max(x),np.max(y))
    ax.plot([lo,hi],[lo,hi],color="gray",linestyle="--",linewidth=1.0,zorder=1)
    ax.set_xlabel(f"{orig_col} [rad]"); ax.set_ylabel(f"{recalc_col} [rad]"); ax.set_title(args.title,fontsize=15)
    extend="max" if np.max(abs_delta)>vmax else "neither"
    cbar=fig.colorbar(sc,ax=ax,extend=extend,pad=0.02); cbar.set_label(r"$|\Delta p95|$ [rad]")
    stats=[f"N = {N}",f"mean(orig) = {mean_x:.3f} rad",f"mean(recalc) = {mean_y:.3f} rad",
           f"Δ = recalc - orig : mean = {mean_delta:.3e}, median = {med_delta:.3e}, std = {std_delta:.3e}",
           f"p95(|Δ|) = {p95_abs:.3e} rad, max |Δ| = {max_abs:.3e} rad",
           f"N_changed (|Δ| > {args.change_eps}) = {n_changed} ({frac_changed:.2f}%)"]
    ax.text(0.02,0.98,"\n".join(stats),transform=ax.transAxes,fontsize=9,va="top",ha="left",
            bbox=dict(boxstyle="round",fc="white",ec="black",lw=1,alpha=0.95),zorder=10)
    hist_base_w, hist_base_h=0.18,0.14; hist_w, hist_h=hist_base_w*args.hist_scale, hist_base_h*args.hist_scale
    hist_ax=inset_axes(ax,width=f"{hist_w*100}%",height=f"{hist_h*100}%",
                       bbox_to_anchor=(args.hist_x,args.hist_y,hist_w,hist_h),bbox_transform=fig.transFigure,loc="lower left",borderpad=1.0)
    max_abs_val=float(np.max(abs_delta)) if abs_delta.size else 0.0
    exp=int(np.floor(np.log10(max_abs_val))) if max_abs_val>0 else 0
    scale=10.0**exp if max_abs_val>0 else 1.0
    if max_abs_val>0 and max_abs_val/scale<1.0: exp-=1; scale=10.0**exp
    hist_vals=abs_delta/scale
    hist_ax.hist(hist_vals,bins=args.bins,color="tab:blue",edgecolor="black")
    hist_ax.axvline(0.0,color="red",linewidth=2.0); hist_ax.set_title("Histogramme |Δp95|",fontsize=9)
    hist_ax.set_xlabel(f"× 10^{exp}",fontsize=8); hist_ax.tick_params(axis="both",which="major",labelsize=8)
    if args.with_zoom:
        zx_center = args.zoom_center_x if args.zoom_center_x is not None else 0.5*(lo+hi)
        zy_center = args.zoom_center_y if args.zoom_center_y is not None else zx_center
        dx=0.06*(hi-lo) if (hi-lo)>0 else 0.1; dy=dx
        zx0,zx1=zx_center-dx/2.0, zx_center+dx/2.0; zy0,zy1=zy_center-dy/2.0, zy_center+dy/2.0
        inz=inset_axes(ax,width=f"{args.zoom_w*100}%",height=f"{args.zoom_h*100}%",
                       bbox_to_anchor=(0.48,0.58,args.zoom_w,args.zoom_h),
                       bbox_transform=fig.transFigure,loc="lower left",borderpad=1.0)
        inz.scatter(x,y,c=abs_delta,s=max(1.0,args.point_size/2.0),alpha=min(1.0,args.alpha+0.1),
                    cmap=args.cmap,edgecolor="none",vmin=0.0,vmax=vmax)
        inz.plot([zx0,zx1],[zx0,zx1],color="gray",linestyle="--",linewidth=0.8)
        inz.set_xlim(zx0,zx1); inz.set_ylim(zy0,zy1); inz.set_title("zoom",fontsize=8)
        try: mark_inset(ax,inz,loc1=2,loc2=4,fc="none",ec="0.5",lw=0.8)
        except Exception: pass
    fig.text(0.5,0.02,r"$\Delta p95 = p95_{recalc} - p95_{orig}$; couleur = $|\Delta p95|$.",ha="center",fontsize=9)
    plt.tight_layout(rect=[0,0.04,1,0.98]); fig.savefig(args.out,dpi=args.dpi); print(f"Wrote: {args.out}")
if __name__=="__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py

###############################################################################
# 6) plot_fig05_hist_cdf_metrics.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py
#!/usr/bin/env python3
from __future__ import annotations
import argparse, textwrap, numpy as np, pandas as pd, matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes, mark_inset
import matplotlib.lines as mlines
def detect_p95_column(df):
    for c in ["p95_20_300_recalc","p95_20_300_circ","p95_20_300_recalced","p95_20_300","p95_circ","p95_recalc","p95"]:
        if c in df.columns: return c
    for c in df.columns:
        if "p95" in c.lower(): return c
    raise KeyError("Aucune colonne 'p95' détectée dans le CSV results.")
def main():
    ap=argparse.ArgumentParser(description="Histogramme + CDF de p95 (circulaire)")
    ap.add_argument("--results", required=True); ap.add_argument("--out", required=True)
    ap.add_argument("--ref-p95", type=float, default=float(np.pi/4)); ap.add_argument("--bins", type=int, default=50)
    ap.add_argument("--dpi", type=int, default=150)
    ap.add_argument("--zoom-x", type=float, default=0.8); ap.add_argument("--zoom-y", type=float, default=35.0)
    ap.add_argument("--zoom-dx", type=float, default=0.30); ap.add_argument("--zoom-dy", type=float, default=30.0)
    ap.add_argument("--zoom-w", type=float, default=0.35); ap.add_argument("--zoom-h", type=float, default=0.22)
    args=ap.parse_args()
    df=pd.read_csv(args.results); p95_col=detect_p95_column(df); p95=df[p95_col].dropna().astype(float).values
    wrapped_corrected=None
    for cand in ("p95_20_300","p95_raw","p95_orig","p95_20_300_raw"):
        if cand in df.columns and cand!=p95_col:
            diff=df[[cand,p95_col]].dropna().astype(float); wrapped_corrected=int((np.abs(diff[cand]-diff[p95_col])>1e-6).sum()); break
    N=p95.size; mean,median,std=float(np.mean(p95)),float(np.median(p95)),float(np.std(p95,ddof=0))
    n_below=int((p95<args.ref_p95).sum()); frac_below=n_below/max(1,N)
    plt.style.use("classic"); fig, ax=plt.subplots(figsize=(14,6))
    counts,bins,patches=ax.hist(p95,bins=args.bins,alpha=0.7,edgecolor="k"); ax.set_ylabel("Effectifs"); ax.set_xlabel(p95_col+" [rad]")
    ax2=ax.twinx(); sorted_p=np.sort(p95); ecdf=np.arange(1,N+1)/N; (cdf_line,)=ax2.plot(sorted_p,ecdf,lw=2)
    ax2.set_ylabel("CDF empirique"); ax2.set_ylim(0.0,1.02)
    ax.axvline(args.ref_p95,color="crimson",linestyle="--",lw=2)
    ax.text(args.ref_p95, ax.get_ylim()[1]*0.45, f"ref = {args.ref_p95:.4f} rad", color="crimson", rotation=90, va="center", ha="right", fontsize=10)
    stat_lines=[f"N = {N}",f"mean = {mean:.3f}",f"median = {median:.3f}",f"std = {std:.3f}"]
    if wrapped_corrected is not None: stat_lines.append(f"wrapped_corrected = {wrapped_corrected}")
    stat_lines.append(f"p(P95 < ref) = {frac_below:.3f} (n={n_below})")
    ax.text(0.02,0.98,"\n".join(stat_lines),transform=ax.transAxes,fontsize=10,va="top",ha="left",
            bbox=dict(boxstyle="round",fc="white",ec="black",lw=1,alpha=0.95))
    patch = patches[0] if len(patches)>0 else None
    if patch is None:
        from matplotlib.patches import Rectangle; patch=Rectangle((0,0),1,1,facecolor="C0",edgecolor="k",alpha=0.7)
    proxy_cdf=mlines.Line2D([],[],color=cdf_line.get_color(),lw=2)
    proxy_ref=mlines.Line2D([],[],color="crimson",linestyle="--",lw=2)
    ax.legend([patch,proxy_cdf,proxy_ref],["Histogramme (effectifs)","CDF empirique","p95 réf"],
              loc="upper left", bbox_to_anchor=(0.02,0.72), frameon=True, fontsize=10)
    inset_ax=inset_axes(ax,width=f"{args.zoom_w*100:.0f}%",height=f"{args.zoom_h*100:.0f}%",loc="center",borderpad=1.0)
    x0,x1=args.zoom_x-args.zoom_dx, args.zoom_x+args.zoom_dx
    mask_x=(p95>=x0)&(p95<=x1); data_inset=p95[mask_x] if mask_x.sum()>=5 else p95
    inset_counts,inset_bins,_=inset_ax.hist(data_inset,bins=min(args.bins,30),alpha=0.9,edgecolor="k")
    ymax_auto=(np.max(inset_counts) if inset_counts.size else 1.0)*1.10; y0=0.0; y1=max(float(args.zoom_y+args.zoom_dy), ymax_auto)
    inset_ax.set_xlim(x0,x1); inset_ax.set_ylim(y0,y1); inset_ax.set_title("zoom",fontsize=10)
    try: mark_inset(ax, inset_ax, loc1=2, loc2=4, fc="none", ec="0.5", lw=0.8)
    except Exception: pass
    ax.set_title(f"Distribution de {p95_col} (MC global)",fontsize=15)
    foot=textwrap.fill((r"Métrique : distance circulaire (mod $2\pi$). "
                        r"p95 = $95^{\mathrm{e}}$ centile de $|\Delta\phi(f)|$ sur $[20,300]$ Hz. "
                        rf"p(\mathrm{{p95}}<\mathrm{{ref}}) = {frac_below:.3f}$ (n = {n_below})."), width=180)
    plt.tight_layout(rect=[0,0.14,1,0.98]); fig=plt.gcf(); fig.text(0.5,0.04,foot,ha="center",va="bottom",fontsize=9)
    fig.savefig(args.out,dpi=args.dpi); print(f"Wrote : {args.out}")
if __name__=="__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py

###############################################################################
# 7) plot_fig06_residual_map.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig06_residual_map.py
#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, numpy as np, pandas as pd, matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator
def wrap_pi(x): return (x + np.pi) % (2 * np.pi) - np.pi
def detect_col(df, candidates):
    for c in candidates:
        if c and c in df.columns: return c
    for c in df.columns:
        lc=c.lower()
        for cand in candidates:
            if cand and cand.lower() in lc: return c
    raise KeyError(f"Impossible de trouver l'une des colonnes : {candidates}")
def main():
    ap=argparse.ArgumentParser(description="Hexbin des résidus sur (m1,m2)")
    ap.add_argument("--results", required=True); ap.add_argument("--out", required=True)
    ap.add_argument("--metric", choices=["dp95","dphi"], default="dp95"); ap.add_argument("--abs", action="store_true")
    ap.add_argument("--m1-col", default="m1"); ap.add_argument("--m2-col", default="m2")
    ap.add_argument("--orig-col", default="p95_20_300"); ap.add_argument("--recalc-col", default="p95_20_300_recalc")
    ap.add_argument("--phi-ref-col", default="phi_ref_fpeak"); ap.add_argument("--phi-mcgt-col", default="phi_mcgt_fpeak")
    ap.add_argument("--gridsize", type=int, default=36); ap.add_argument("--mincnt", type=int, default=3)
    ap.add_argument("--cmap", default="viridis"); ap.add_argument("--vclip", default="1,99")
    ap.add_argument("--scale-exp", type=int, default=-7); ap.add_argument("--threshold", type=float, default=1e-6)
    ap.add_argument("--figsize", default="15,9"); ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument("--manifest", action="store_true")
    args=ap.parse_args()
    df=pd.read_csv(args.results).dropna(subset=[args.m1_col,args.m2_col])
    x=df[args.m1_col].astype(float).values; y=df[args.m2_col].astype(float).values; N=len(df)
    if args.metric=="dp95":
        col_o=detect_col(df,[args.orig_col,"p95_20_300","p95"]); col_r=detect_col(df,[args.recalc_col,"p95_20_300_recalc","p95_recalc"])
        raw=df[col_r].astype(float).values - df[col_o].astype(float).values; metric_name=r"\Delta p_{95}"
    else:
        col_ref=detect_col(df,[args.phi_ref_col,"phi_ref_fpeak"]); col_mc=detect_col(df,[args.phi_mcgt_col,"phi_mcgt_fpeak","phi_mcgt"])
        raw=wrap_pi(df[col_mc].astype(float).values - df[col_ref].astype(float).values); metric_name=r"\Delta \phi"
    metric_label = rf"|{metric_name}|" if args.abs else rf"{metric_name}"
    scale_factor=10.0**args.scale_exp; scaled= (np.abs(raw) if args.abs else raw) / scale_factor
    p_lo,p_hi=(float(t) for t in args.vclip.split(",")); vmin=float(np.percentile(scaled,p_lo)); vmax=float(np.percentile(scaled,p_hi))
    med,mean,std,p95=float(np.median(scaled)),float(np.mean(scaled)),float(np.std(scaled,ddof=0)),float(np.percentile(scaled,95.0))
    frac_over=float(np.mean(np.abs(raw) > args.threshold))
    fig_w,fig_h=(float(s) for s in args.figsize.split(",")); plt.style.use("classic")
    fig=plt.figure(figsize=(fig_w,fig_h),dpi=args.dpi)
    ax_main=fig.add_axes([0.07,0.145,0.56,0.74]); ax_cbar=fig.add_axes([0.645,0.145,0.025,0.74])
    right_left=0.75; right_w=0.23; ax_cnt=fig.add_axes([right_left,0.60,right_w,0.30]); ax_hist=fig.add_axes([right_left,0.20,right_w,0.30])
    hb=ax_main.hexbin(x,y,C=scaled,gridsize=args.gridsize,reduce_C_function=np.median,mincnt=args.mincnt,vmin=vmin,vmax=vmax,cmap=args.cmap)
    cbar=fig.colorbar(hb,cax=ax_cbar); exp_txt=f"× 10^{args.scale_exp}"; cbar.set_label(rf"{metric_label} {exp_txt} [rad]")
    ax_main.set_title(rf"Carte des résidus ${metric_label}$ sur $(m_1,m_2)$"+(" (absolu)" if args.abs else ""))
    ax_main.set_xlabel("m1"); ax_main.set_ylabel("m2")
    hb_counts=ax_cnt.hexbin(x,y,gridsize=args.gridsize,cmap="gray_r"); fig.colorbar(hb_counts,ax=ax_cnt,orientation="vertical",fraction=0.046,pad=0.03).set_label("Counts")
    ax_cnt.set_title("Counts (par cellule)"); ax_cnt.set_xlabel("m1"); ax_cnt.set_ylabel("m2")
    ax_cnt.xaxis.set_major_locator(MaxNLocator(nbins=5)); ax_cnt.yaxis.set_major_locator(MaxNLocator(nbins=5))
    counts_arr=hb_counts.get_array(); n_active=int(np.sum(counts_arr[counts_arr>=args.mincnt]))
    ax_hist.hist(scaled,bins=40,color="#1f77b4",edgecolor="black",linewidth=0.6); ax_hist.set_title("Distribution globale")
    ax_hist.set_xlabel(rf"metric {exp_txt} [rad]"); ax_hist.set_ylabel("fréquence")
    ax_hist.text(0.02,0.02,"\n".join([rf"median={med:.2f}, mean={mean:.2f}",rf"std={std:.2f}, p95={p95:.2f} {exp_txt} [rad]",rf"fraction |metric|>{args.threshold:.0e} rad = {100*frac_over:.2f}%"]),
                 transform=ax_hist.transAxes,ha="left",va="bottom",fontsize=9,bbox=dict(boxstyle="round",fc="white",ec="0.5",alpha=0.9))
    fig.subplots_adjust(left=0.07,right=0.96,top=0.96,bottom=0.12,wspace=0.34,hspace=0.30)
    fig.text(0.5,0.053,f"Réduction par médiane (gridsize={args.gridsize}, mincnt={args.mincnt}). vmin={vmin:.6g}, vmax={vmax:.6g}.",ha="center",fontsize=10)
    fig.text(0.5,0.032,f"Stats globales: median={med:.2f}, mean={mean:.2f}, std={std:.2f}, p95={p95:.2f} {exp_txt} [rad]. N={N}, cellules actives (≥{args.mincnt}) = {n_active}/{N}.",ha="center",fontsize=10)
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    fig.savefig(args.out,dpi=args.dpi,bbox_inches="tight"); print(f"[OK] Figure écrite: {args.out}")
    if args.manifest:
        man_path=os.path.splitext(args.out)[0]+".manifest.json"
        manifest={"script":"plot_fig06_residual_map.py","generated_at":pd.Timestamp.utcnow().isoformat()+"Z",
                  "inputs":{"csv":args.results,"m1_col":args.m1_col,"m2_col":args.m2_col},
                  "metric":{"name":args.metric,"absolute":bool(args.abs),"orig_col":args.orig_col,"recalc_col":args.recalc_col,
                            "phi_ref_col":args.phi_ref_col,"phi_mcgt_col":args.phi_mcgt_col},
                  "plot_params":{"gridsize":int(args.gridsize),"mincnt":int(args.mincnt),"cmap":args.cmap,
                                 "vclip_percentiles":[float(p_lo),float(p_hi)],"vmin_scaled":float(vmin),"vmax_scaled":float(vmax),
                                 "scale_exp":int(args.scale_exp),"threshold_rad":float(args.threshold),
                                 "figsize":[fig_w,fig_h],"dpi":int(args.dpi)},
                  "dataset":{"N":int(N),"n_active_points":int(n_active)},
                  "figure_path":args.out}
        with open(man_path,"w",encoding="utf-8") as f: json.dump(manifest,f,indent=2); print(f"[OK] Manifest écrit: {man_path}")
if __name__=="__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig06_residual_map.py

###############################################################################
# 8) plot_fig07_synthesis.py
###############################################################################
cat <<'PY' > zz-scripts/chapter10/plot_fig07_synthesis.py
#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, csv, numpy as np, matplotlib.pyplot as plt
from dataclasses import dataclass
from typing import Any, List
from matplotlib.gridspec import GridSpec
def load_manifest(path): 
    with open(path,encoding="utf-8") as f: return json.load(f)
def _first(d, keys, default=np.nan):
    for k in keys:
        if k in d and d[k] is not None: return d[k]
    return default
def _param(params, candidates, default=np.nan): return _first(params, candidates, default)
@dataclass
class Series:
    label: str; N: np.ndarray; coverage: np.ndarray; err_low: np.ndarray; err_high: np.ndarray; width_mean: np.ndarray; alpha: float; params: dict
def series_from_manifest(man, label_override=None):
    results=man.get("results",[])
    if not results: raise ValueError("Manifest ne contient pas de 'results'.")
    N=np.array([_first(r,["N"],np.nan) for r in results],dtype=float)
    coverage=np.array([_first(r,["coverage"],np.nan) for r in results],dtype=float)
    err_low=np.array([_first(r,["coverage_err95_low","coverage_err_low"],0.0) for r in results],dtype=float)
    err_high=np.array([_first(r,["coverage_err95_high","coverage_err_high"],0.0) for r in results],dtype=float)
    width_mean=np.array([_first(r,["width_mean_rad","width_mean"],np.nan) for r in results],dtype=float)
    params=man.get("params",{}); alpha=float(_param(params,["alpha","conf_alpha"],0.05))
    label=label_override or man.get("series_label") or man.get("label") or os.path.basename(man.get("figure_path","")) or "série"
    return Series(label,N,coverage,err_low,err_high,width_mean,alpha,params)
def save_summary_csv(series_list: List[Series], out_csv: str) -> None:
    os.makedirs(os.path.dirname(out_csv) or ".", exist_ok=True)
    fields=["series","N","coverage","err95_low","err95_high","width_mean","outer_B","inner_B","alpha"]
    with open(out_csv,"w",newline="",encoding="utf-8") as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader()
        for s in series_list:
            outer_B=int(_param(s.params,["outer","outer_B","B_outer","outerB","Bouter"],np.nan)) if np.isfinite(_param(s.params,["outer","outer_B","B_outer","outerB","Bouter"],np.nan)) else ""
            inner_B=int(_param(s.params,["inner","inner_B","B_inner","innerB","Binner"],np.nan)) if np.isfinite(_param(s.params,["inner","inner_B","B_inner","innerB","Binner"],np.nan)) else ""
            for i in range(len(s.N)):
                w.writerow({"series":s.label,"N":int(s.N[i]) if np.isfinite(s.N[i]) else "",
                            "coverage":float(s.coverage[i]) if np.isfinite(s.coverage[i]) else "",
                            "err95_low":float(s.err_low[i]) if np.isfinite(s.err_low[i]) else "",
                            "err95_high":float(s.err_high[i]) if np.isfinite(s.err_high[i]) else "",
                            "width_mean":float(s.width_mean[i]) if np.isfinite(s.width_mean[i]) else "",
                            "outer_B":outer_B,"inner_B":inner_B,"alpha":s.alpha})
def plot_synthesis(series_list: List[Series], out_png: str, figsize=(14,6), dpi=300, ymin_cov=None, ymax_cov=None):
    plt.style.use("classic")
    fig=plt.figure(figsize=figsize, constrained_layout=False, dpi=dpi)
    gs=GridSpec(1,2,figure=fig,width_ratios=[5,3],wspace=0.25); ax1=fig.add_subplot(gs[0,0]); ax2=fig.add_subplot(gs[0,1])
    colors=plt.rcParams['axes.prop_cycle'].by_key().get('color', ["tab:blue","tab:orange","tab:green","tab:red"])
    for i,s in enumerate(series_list):
        col=colors[i % len(colors)]
        ax1.errorbar(s.N,s.coverage,yerr=[s.err_low,s.err_high],fmt="o-",lw=1.7,ms=6,color=col,ecolor=col,capsize=3,label=f"{s.label} (α={s.alpha:.2f})")
        ax2.plot(s.N,s.width_mean,"-",lw=2.0,color=col,label=s.label)
    uniq_alpha=set(round(s.alpha,4) for s in series_list if np.isfinite(s.alpha))
    if len(uniq_alpha)==1:
        a=list(uniq_alpha)[0]; ax1.axhline(1-a,color="crimson",ls="--",lw=1.5,label=f"Niveau nominal {int((1-a)*100)}%")
    ax1.set_xlabel("Taille d'échantillon N"); ax1.set_ylabel("Couverture (IC contient la référence)"); ax1.set_title("Couverture vs N")
    if (ymin_cov is not None) or (ymax_cov is not None):
        ymin=ymin_cov if ymin_cov is not None else ax1.get_ylim()[0]; ymax=ymax_cov if ymax_cov is not None else ax1.get_ylim()[1]; ax1.set_ylim(ymin,ymax)
    ax1.legend(loc="lower right", frameon=True)
    ax2.set_xlabel("Taille d'échantillon N"); ax2.set_ylabel("Largeur moyenne de l'IC [rad]"); ax2.set_title("Largeur moyenne d’IC vs N"); ax2.legend(loc="best", frameon=True)
    fig.savefig(out_png,dpi=dpi); print(f"Wrote: {out_png}")
def main():
    ap=argparse.ArgumentParser(description="Synthèse multi-manifests (fig07)")
    ap.add_argument("--manifests", nargs="+", required=True); ap.add_argument("--labels", nargs="*", default=None)
    ap.add_argument("--out", required=True); ap.add_argument("--summary-csv", default=None)
    ap.add_argument("--dpi", type=int, default=300); ap.add_argument("--ymin-coverage", type=float, default=None); ap.add_argument("--ymax-coverage", type=float, default=None)
    args=ap.parse_args()
    if args.labels and len(args.labels)!=len(args.manifests): raise SystemExit("Si --labels est fourni, il doit y en avoir autant que de --manifests.")
    series_list=[]
    for i,path in enumerate(args.manifests):
        man=load_manifest(path); label=args.labels[i] if args.labels else None; series_list.append(series_from_manifest(man,label_override=label))
    if args.summary_csv: save_summary_csv(series_list, args.summary_csv); print(f"[OK] Summary CSV: {args.summary_csv}")
    plot_synthesis(series_list,args.out,dpi=args.dpi,ymin_cov=args.ymin_coverage,ymax_cov=args.ymax_coverage)
if __name__=="__main__": main()
PY
chmod +x zz-scripts/chapter10/plot_fig07_synthesis.py

###############################################################################
# Tests rapides : exécution minimale de chaque figure
###############################################################################
echo "[TEST] fig01"
python3 "$SCRIPTS_DIR/plot_fig01_iso_p95_maps.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig01_iso_p95.png" \
  --levels 10 --dpi 120

echo "[TEST] fig02"
python3 "$SCRIPTS_DIR/plot_fig02_scatter_phi_at_fpeak.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig02_scatter_phi.png" \
  --pi-ticks --clip-pi --boot-ci 120

echo "[TEST] fig03"
python3 "$SCRIPTS_DIR/plot_fig03_convergence_p95_vs_n.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig03_convergence.png" \
  --B 200 --npoints 10 --dpi 120

echo "[TEST] fig03b (series A)"
python3 "$SCRIPTS_DIR/plot_fig03b_bootstrap_coverage_vs_n.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig03b_cov_A.png" \
  --outer 200 --inner 400 --npoints 6 --minN 30 --seed 111 --dpi 120

echo "[TEST] fig03b (series B)"
python3 "$SCRIPTS_DIR/plot_fig03b_bootstrap_coverage_vs_n.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig03b_cov_B.png" \
  --outer 200 --inner 400 --npoints 6 --minN 30 --seed 222 --dpi 120

echo "[TEST] fig04"
python3 "$SCRIPTS_DIR/plot_fig04_scatter_p95_recalc_vs_orig.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig04_scatter_p95.png" \
  --with-zoom --dpi 120

echo "[TEST] fig05"
python3 "$SCRIPTS_DIR/plot_fig05_hist_cdf_metrics.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig05_hist_cdf.png" \
  --bins 40 --dpi 120

echo "[TEST] fig06"
python3 "$SCRIPTS_DIR/plot_fig06_residual_map.py" \
  --results "$DATA_DIR/dummy_results.csv" \
  --out "$OUT_DIR/fig06_residual_hexbin.png" \
  --metric dp95 --abs --gridsize 28 --dpi 120

echo "[TEST] fig07 (synthèse de 2 manifests)"
python3 "$SCRIPTS_DIR/plot_fig07_synthesis.py" \
  --manifests "$OUT_DIR/fig03b_cov_A.manifest.json" "$OUT_DIR/fig03b_cov_B.manifest.json" \
  --labels "serie-A" "serie-B" \
  --out "$OUT_DIR/fig07_synthesis.png" \
  --summary-csv "$OUT_DIR/fig07_summary.csv" \
  --dpi 120

echo "[DONE] Outputs in $OUT_DIR"
