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
