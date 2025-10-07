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
    fig.subplots_adjust(left=0.06,right=0.98,top=0.95,bottom=0.14,wspace=0.28); fig.savefig(args.out, dpi=args.dpi); print(f"Wrote: {args.out}")
if __name__=="__main__": main()
