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
