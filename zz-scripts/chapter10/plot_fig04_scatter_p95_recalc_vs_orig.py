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
    fig.subplots_adjust(left=0.10,right=0.98,top=0.95,bottom=0.10); fig.savefig(args.out, dpi=args.dpi); print(f"Wrote: {args.out}")
if __name__=="__main__": main()
