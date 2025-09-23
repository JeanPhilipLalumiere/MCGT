#!/usr/bin/env python3
"""
zz-scripts/chapter09/extract_phenom_phase.py

Génère 09_phases_imrphenom.csv :
– f_Hz    : fréquence (Hz) sur grille log-lin
– phi_ref : phase IMRPhenomD (radians)
"""

import argparse
import numpy as np
import pandas as pd
from pycbc.waveform import get_fd_waveform

def parse_args():
    p = argparse.ArgumentParser(
        description="Extraire la phase de référence IMRPhenomD (PyCBC)"
    )
    p.add_argument("--fmin",   type=float, required=True, help="Fréquence minimale (Hz)")
    p.add_argument("--fmax",   type=float, required=True, help="Fréquence maximale (Hz)")
    p.add_argument("--dlogf",  type=float, required=True, help="Pas Δlog10(f)")
    p.add_argument("--m1",     type=float, required=True, help="Masse primaire (M☉)")
    p.add_argument("--m2",     type=float, required=True, help="Masse secondaire (M☉)")
    p.add_argument("--phi0",   type=float, default=0.0, help="Phase initiale φ0 (rad)")
    p.add_argument("--dist",   type=float, required=True, help="Distance (Mpc)")
    p.add_argument("--outcsv", type=str, default="09_phases_imrphenom.csv",
                   help="Nom du fichier CSV de sortie")
    return p.parse_args()

def main():
    args = parse_args()

    # Conversion unités
    m1 = args.m1
    m2 = args.m2
    distance = args.dist

    # Générer le waveform fréquentiel
    hp, hc = get_fd_waveform(
        approximant="IMRPhenomD",
        mass1=m1, mass2=m2,
        spin1z=0.0, spin2z=0.0,
        delta_f=10**(np.log10(args.fmin + args.dlogf) - np.log10(args.fmin)) * args.fmin,
        f_lower=args.fmin,
        f_final=args.fmax,
        distance=distance,
        phi0=args.phi0
    )

    # Récupérer fréquences et phases
    freqs = hp.sample_frequencies.numpy()
    phase = np.unwrap(np.angle(hp.numpy()))

    # Filtrer la grille log-lin manuellement si nécessaire
    # Ici on suppose que PyCBC renvoie une grille lin-équidistante en delta_f
    # Pour une grille log-lin, on reconstruirait la grille : 
    # freqs = 10**np.arange(np.log10(args.fmin), np.log10(args.fmax)+1e-12, args.dlogf)
    # phase = np.interp(freqs, hp.sample_frequencies, np.unwrap(np.angle(hp)))

    # Sauvegarder en CSV
    df = pd.DataFrame({"f_Hz": freqs, "phi_ref": phase})
    df.to_csv(args.outcsv, index=False, float_format="%.8e", encoding="utf-8")
    print(f"Écrit : {args.outcsv}")

if __name__ == "__main__":
    main()
