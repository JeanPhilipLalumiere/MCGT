#!/usr/bin/env python3
import csv, glob, math, os, shutil, sys

TARGET_GLOBS = [
    "zz-data/chapter09/09_comparison_milestones*.csv",
    "zz-donnees/chapitre9/09_jalons_comparaison*.csv",
]

PHASE_COLS = [
    "phi_ref_at_fpeak",
    "phi_mcgt_at_fpeak",
    "phi_mcgt_at_fpeak_raw",
    "phi_mcgt_at_fpeak_cal",
    "obs_phase",
    "sigma_phase",
]

THRESH_RAD = 7.0  # > ~2π/3 => très probablement en degrés

def detect_degrees(rows):
    """Heuristique simple: si la valeur absolue max des colonnes de phase dépasse THRESH_RAD, on considère que c'est en degrés."""
    max_abs = 0.0
    for r in rows:
        for c in PHASE_COLS:
            if c in r and r[c] not in (None, ""):
                try:
                    v = float(r[c])
                    if abs(v) > max_abs:
                        max_abs = abs(v)
                except ValueError:
                    pass
    return max_abs > THRESH_RAD

def convert_file(path):
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fieldnames = reader.fieldnames or []

    if not rows:
        return False, "SKIP(empty)"

    is_deg = detect_degrees(rows)
    if not is_deg:
        return False, "OK(already_rad)"

    # backup
    bak = path + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)

    # conversion
    for r in rows:
        for c in PHASE_COLS:
            if c in r and r[c] not in (None, ""):
                try:
                    r[c] = str(float(r[c]) * (math.pi / 180.0))
                except ValueError:
                    # laisser tel quel si non numérique
                    pass

    # écriture
    tmp = path + ".tmp"
    with open(tmp, "w", newline="", encoding="utf-8") as fw:
        writer = csv.DictWriter(fw, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    os.replace(tmp, path)
    return True, "CONVERTED(deg->rad)"

def main():
    any_changed = False
    for pattern in TARGET_GLOBS:
        for p in glob.glob(pattern):
            changed, msg = convert_file(p)
            print(f"{p}: {msg}")
            any_changed = any_changed or changed
    sys.exit(0)

if __name__ == "__main__":
    main()
