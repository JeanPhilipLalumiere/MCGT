#!/usr/bin/env python3
from pathlib import Path
import re, sys, json

FILES = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]

SENTINEL = "# --- cli global proxy v7 ---"

# Défauts à garantir (merge sans écraser l’existant)
WANTED_DEFAULTS = {
    # communs déjà utilisés
    "p95_col": None,
    "m1_col": "phi0",
    "m2_col": "phi_ref_fpeak",
    "metric": "dp95",
    "mincnt": 1,
    "gridsize": 60,
    "figsize": "8,6",
    "dpi": 300,
    "title": "",
    "title_left": "",
    "title_right": "",
    "hist_x": 0,
    "hist_y": 0,
    "hist_scale": 1.0,
    "with_zoom": False,
    "zoom_x": None, "zoom_y": None, "zoom_dx": None, "zoom_dy": None,
    "zoom_center_n": None,
    "cmap": "viridis",
    "point_size": 10,
    "threshold": 0.0,
    "angular": False,
    "vclip": "0,100",

    # erreurs actuelles
    "minN": 10,          # fig03b: int(args.minN)
    "scale_exp": 0,      # fig06 : 10.0 ** args.scale_exp

    # axes coverage (déjà apparus)
    "ymin_coverage": 0.0,
    "ymax_coverage": 1.0,

    # flags vus/possibles
    "hires2000": False,
}

START_RE = re.compile(r'^\s*#\s*--- cli global proxy v7 ---\s*$', re.M)
END_RE   = re.compile(r'^\s*#\s*--- end cli global proxy v7 ---\s*$', re.M)
DICT_START_RE = re.compile(r'^\s*_COMMON_DEFAULTS\s*=\s*\{\s*$', re.M)

def parse_defaults_block(text: str, i0: int, i1: int):
    """Retourne (full_text, dict_start_idx, dict_end_idx, dict_lines, existing_map) dans la fenêtre [i0,i1)."""
    window = text[i0:i1]
    m = DICT_START_RE.search(window)
    if not m:
        return None
    ds = i0 + m.start()
    # avancer jusqu'à la fermeture "}" qui clôt le dict
    j = text.find("\n", ds)
    if j == -1: return None
    # scan simple par compteur d’accolades
    brace = 0
    k = ds
    while k < i1:
        ch = text[k]
        if ch == "{": brace += 1
        elif ch == "}":
            brace -= 1
            if brace == 0:
                de = k  # index du '}' fermant
                break
        k += 1
    else:
        return None
    dict_text = text[ds:de+1]
    dict_lines = dict_text.splitlines(True)
    # extraire paires 'key': value,
    EXIST_RE = re.compile(r"^\s*'([^']+)'\s*:\s*(.+?),\s*$")
    existing = {}
    for ln in dict_lines:
        m2 = EXIST_RE.match(ln)
        if m2:
            key = m2.group(1)
            val = m2.group(2).strip()
            existing[key] = val
    return ds, de+1, dict_lines, existing

def pyrepr(v):
    if isinstance(v, str):
        return repr(v)
    elif v is None:
        return "None"
    else:
        return str(v)

def update_file(p: Path) -> bool:
    s = p.read_text(encoding="utf-8")
    ms = list(START_RE.finditer(s))
    me = list(END_RE.finditer(s))
    if not ms or not me:
        print(f"[SKIP] proxy v7 block not found in {p}")
        return False
    # On prend le 1er bloc (il ne doit y en avoir qu’un)
    i0 = ms[0].start()
    i1 = me[0].end()
    parsed = parse_defaults_block(s, i0, i1)
    if not parsed:
        print(f"[ERR] defaults dict not found in proxy v7 block for {p}")
        return False
    ds, de, dict_lines, existing = parsed

    # calculer ce qu’il faut ajouter
    to_add = [(k, WANTED_DEFAULTS[k]) for k in WANTED_DEFAULTS.keys() if k not in existing]
    if not to_add:
        print(f"[OK] defaults already complete in {p}")
        return False

    # insérer avant la ligne '}' finale
    out = []
    # recopier tout jusqu’au dict
    out.append(s[:ds])
    # reconstruire dict
    # 1) ligne d’ouverture
    out.append(dict_lines[0])
    # 2) lignes existantes (inchangées)
    for ln in dict_lines[1:-1]:
        out.append(ln)
    # 3) ajouts
    for k, v in to_add:
        out.append(f"    '{k}': {pyrepr(v)},\n")
    # 4) fermeture
    out.append(dict_lines[-1])
    # 5) le reste du fichier
    out.append(s[de:])

    p.write_text("".join(out), encoding="utf-8")
    print(f"[PATCH] added {len(to_add)} default(s) in {p}: " +
          ", ".join(k for k,_ in to_add))
    return True

if __name__ == "__main__":
    changed = False
    for f in FILES:
        if f.exists():
            changed |= update_file(f)
        else:
            print(f"[MISS] {f}")
    if not changed:
        print("[NOTE] nothing changed")
