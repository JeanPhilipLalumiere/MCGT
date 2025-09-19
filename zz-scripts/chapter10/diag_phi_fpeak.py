#!/usr/bin/env python3
# zz-scripts/chapter10/diag_phi_fpeak.py
"""
Diagnostic pour lignes problématiques lors du calcul de phi_ref_fpeak / phi_mcgt_fpeak.

Usage:
python zz-scripts/chapter10/diag_phi_fpeak.py \
  --results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv \
  --ref-grid zz-data/chapter09/09_phases_imrphenom.csv \
  --out-diagnostics zz-data/chapter10/diag_phi_fpeak_report.csv \
  --thresh 1e3
"""
from __future__ import annotations
import argparse
import csv
import math
import numpy as np
import pandas as pd
from mcgt.backends.ref_phase import compute_phi_ref
from mcgt.phase import phi_mcgt

def safe_float(x):
    try:
        return float(x)
    except Exception:
        return np.nan

def is_bad_phi(val, thresh):
    if val is None: return True
    try:
        v = float(val)
    except Exception:
        return True
    if math.isnan(v) or math.isinf(v): return True
    return abs(v) > thresh

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--results", required=True)
    p.add_argument("--ref-grid", required=True)
    p.add_argument("--out-diagnostics", default="zz-data/chapter10/diag_phi_fpeak_report.csv")
    p.add_argument("--thresh", type=float, default=1e3, help="seuil pour considérer une phi aberrante")
    args = p.parse_args()

    df = pd.read_csv(args.results)
    f_ref = np.loadtxt(args.ref_grid, delimiter=',', skiprows=1, usecols=[0])
    # ensure sorted and finite
    f_ref = np.asarray(f_ref)
    f_ref = f_ref[np.isfinite(f_ref)]
    if f_ref.size < 2:
        raise SystemExit("La grille de référence contient <2 points après nettoyage.")

    rows = []
    for i, row in df.iterrows():
        rec = dict(id=int(row.get("id", -1)))
        # basic params
        rec['idx'] = i
        rec['m1'] = row.get("m1")
        rec['m2'] = row.get("m2")
        rec['k'] = row.get("k", "")
        # existing recorded phi values
        rec['phi_ref_fpeak_recorded'] = row.get("phi_ref_fpeak", "")
        rec['phi_mcgt_fpeak_recorded'] = row.get("phi_mcgt_fpeak", "")

        bad_flag = False
        msg = ""

        # quick detect recorded bad values
        if is_bad_phi(rec['phi_mcgt_fpeak_recorded'], args.thresh) or is_bad_phi(rec['phi_ref_fpeak_recorded'], args.thresh):
            bad_flag = True
            msg += "recorded_phi_bad;"

        # Try to recompute using the full f_ref (do not slice it yet)
        try:
            m1 = safe_float(row.get("m1"))
            m2 = safe_float(row.get("m2"))
            if np.isnan(m1) or np.isnan(m2):
                raise ValueError("m1/m2 not numeric")
            # compute phi_ref on full grid (robust fallback)
            phi_ref_full = compute_phi_ref(f_ref, m1, m2)
            # pick f_peak estimate: if f_peak column exists use it, else use argmin|phi'|? for now try f_peak column
            f_peak = None
            for cand in ("f_peak","fpeak","f_peak_Hz"):
                if cand in row:
                    f_peak = row.get(cand)
                    break
            # if f_peak not present, fall back to single point (e.g. median of f_ref)
            if f_peak is None or (isinstance(f_peak, float) and (np.isnan(f_peak) or np.isinf(f_peak))):
                # fallback: choose middle of band [20,300] if within f_ref
                # prefer to choose median frequency of available ref grid
                f_peak = float(np.median(f_ref))
            else:
                f_peak = float(f_peak)

            # find nearest index to f_peak
            idx = (np.abs(f_ref - f_peak)).argmin()
            phi_ref_at_fpeak = float(phi_ref_full[idx])

            # compute phi_mcgt on full grid (use theta from row)
            theta = {}
            for key in ("m1","m2","q0star","alpha","phi0","tc","dist","incl"):
                if key in row:
                    theta[key] = safe_float(row[key])
            # compute phi_mcgt may raise; catch it
            try:
                phi_mcgt_full = phi_mcgt(f_ref, theta)
                phi_mcgt_at_fpeak = float(phi_mcgt_full[idx])
            except Exception as e:
                phi_mcgt_at_fpeak = None
                msg += f"phi_mcgt_error:{e};"
                bad_flag = True

            rec['f_peak_used'] = f_peak
            rec['f_ref_len'] = int(f_ref.size)
            rec['phi_ref_at_fpeak_recomputed'] = phi_ref_at_fpeak
            rec['phi_mcgt_at_fpeak_recomputed'] = phi_mcgt_at_fpeak

            # mark if recomputed values are bad
            if phi_mcgt_at_fpeak is None or is_bad_phi(phi_mcgt_at_fpeak, args.thresh):
                bad_flag = True
                msg += "recomputed_phi_bad;"

        except Exception as e:
            bad_flag = True
            msg += f"recompute_error:{e};"
            rec['f_peak_used'] = None
            rec['f_ref_len'] = int(f_ref.size)
            rec['phi_ref_at_fpeak_recomputed'] = ""
            rec['phi_mcgt_at_fpeak_recomputed'] = ""

        rec['bad'] = bad_flag
        rec['msg'] = msg
        rows.append(rec)

    # write diagnostics CSV of problematic rows only
    out_rows = [r for r in rows if r['bad']]
    if not out_rows:
        print("Aucun cas problématique détecté selon le seuil.")
    else:
        keys = ['idx','id','m1','m2','k','f_peak_used','f_ref_len',
                'phi_ref_fpeak_recorded','phi_ref_at_fpeak_recomputed',
                'phi_mcgt_fpeak_recorded','phi_mcgt_at_fpeak_recomputed',
                'msg']
        with open(args.out_diagnostics, "w", newline='') as fh:
            w = csv.DictWriter(fh, fieldnames=keys)
            w.writeheader()
            for r in out_rows:
                roww = {k: r.get(k,"") for k in keys}
                w.writerow(roww)
        print(f"Wrote diagnostics ({len(out_rows)} problematic rows) -> {args.out_diagnostics}")

if __name__ == "__main__":
    main()
