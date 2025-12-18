#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Aucun manifest n’a été supprimé, seulement modifié si indiqué.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH 01 – Correction des chapter_manifest_0X.json (02,03,04,07,09) =="
echo

python - << 'PYEOF'
import json
import pathlib
import datetime

root = pathlib.Path("zz-manifests/chapters")
ts = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

def backup(path, original_text):
    bak = path.with_suffix(path.suffix + f".bak_patch_{ts}")
    bak.write_text(original_text, encoding="utf-8")
    print(f"  [BACKUP] {bak}")

def replace_in(lst, old, new, label):
    changed = False
    if old in lst:
        if new in lst:
            lst.remove(old)
            print(f"    [{label}] remove {old!r} (déjà remplacé par {new!r})")
        else:
            idx = lst.index(old)
            lst[idx] = new
            print(f"    [{label}] {old!r} -> {new!r}")
        changed = True
    return changed

def ensure(lst, new, label):
    if new not in lst:
        lst.append(new)
        print(f"    [{label}] + {new!r}")
        return True
    return False

def patch_ch02(obj):
    changed = False
    files = obj.setdefault("files", {})
    data_inputs = files.get("data_inputs", [])

    # Renommage des data_inputs
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter02/02_chronology_milestones.csv",
        "zz-data/chapter02/02_timeline_milestones.csv",
        "ch02:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter02/02_derivative_P_data.dat",
        "zz-data/chapter02/02_P_derivative_data.dat",
        "ch02:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter02/02_grid_data_P_vs_T.dat",
        "zz-data/chapter02/02_P_vs_T_grid_data.dat",
        "ch02:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter02/02_primordial_spectrum.json",
        "zz-data/chapter02/02_primordial_spectrum_spec.json",
        "ch02:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter02/02_relative_errors_chronology.csv",
        "zz-data/chapter02/02_relative_error_timeline.csv",
        "ch02:data_inputs",
    )

    # Ajout de 02_FG_series.csv si absent
    changed |= ensure(
        data_inputs,
        "zz-data/chapter02/02_FG_series.csv",
        "ch02:data_inputs",
    )

    files["data_inputs"] = data_inputs

    # Figures : on impose la liste canonique
    new_figs = [
        "zz-figures/chapter02/02_fig_00_spectrum.png",
        "zz-figures/chapter02/02_fig_01_p_vs_t_evolution.png",
        "zz-figures/chapter02/02_fig_02_calibration.png",
        "zz-figures/chapter02/02_fig_03_relative_errors.png",
        "zz-figures/chapter02/02_fig_04_pipeline_diagram.png",
        "zz-figures/chapter02/02_fig_05_fg_series.png",
        "zz-figures/chapter02/02_fig_06_alpha_fit.png",
    ]
    if files.get("figures") != new_figs:
        files["figures"] = new_figs
        print("    [ch02:figures] liste remplacée par la version canonique 02_fig_XX_*.png")
        changed = True

    obj["files"] = files
    return changed

def patch_ch03(obj):
    changed = False
    files = obj.setdefault("files", {})

    # DATA
    data_inputs = files.get("data_inputs", [])
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter03/03_stability_fR_boundary.csv",
        "zz-data/chapter03/03_fR_stability_boundary.csv",
        "ch03:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter03/03_stability_fR_data.csv",
        "zz-data/chapter03/03_fR_stability_data.csv",
        "ch03:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter03/03_stability_fR_domain.csv",
        "zz-data/chapter03/03_fR_stability_domain.csv",
        "ch03:data_inputs",
    )
    files["data_inputs"] = data_inputs

    # FIGURES : corrections ponctuelles
    figures = files.get("figures", [])

    changed |= replace_in(
        figures,
        "zz-figures/chapter03/03_fig_01_stability_fR_domain.png",
        "zz-figures/chapter03/03_fig_01_fR_stability_domain.png",
        "ch03:figures",
    )
    changed |= replace_in(
        figures,
        "zz-figures/chapter03/03_fig_05_milestones_interpolation.png",
        "zz-figures/chapter03/03_fig_05_interpolated_milestones.png",
        "ch03:figures",
    )

    files["figures"] = figures
    obj["files"] = files
    return changed

def patch_ch04(obj):
    changed = False
    files = obj.setdefault("files", {})
    data_inputs = files.get("data_inputs", [])

    changed |= replace_in(
        data_inputs,
        "zz-data/chapter04/04_T_reference_grid.dat",
        "zz-data/chapter04/04_P_vs_T.dat",
        "ch04:data_inputs",
    )
    files["data_inputs"] = data_inputs

    # Figures canoniques 04_fig_XX_*.png
    new_figs = [
        "zz-figures/chapter04/04_fig_01_invariants_schematic.png",
        "zz-figures/chapter04/04_fig_02_invariants_histogram.png",
        "zz-figures/chapter04/04_fig_03_invariants_vs_t.png",
        "zz-figures/chapter04/04_fig_04_relative_deviations.png",
    ]
    if files.get("figures") != new_figs:
        files["figures"] = new_figs
        print("    [ch04:figures] liste remplacée par la version canonique 04_fig_XX_*.png")
        changed = True

    obj["files"] = files
    return changed

def patch_ch07(obj):
    changed = False
    files = obj.setdefault("files", {})
    data_inputs = files.get("data_inputs", [])

    changed |= replace_in(
        data_inputs,
        "zz-data/chapter07/07_main_scalar_perturbations_data.csv",
        "zz-data/chapter07/07_perturbations_main_data.csv",
        "ch07:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter07/07_scalar_perturbations_meta.json",
        "zz-data/chapter07/07_meta_perturbations.json",
        "ch07:data_inputs",
    )
    changed |= replace_in(
        data_inputs,
        "zz-data/chapter07/07_scalar_perturbations_params.json",
        "zz-data/chapter07/07_perturbations_params.json",
        "ch07:data_inputs",
    )

    files["data_inputs"] = data_inputs
    obj["files"] = files
    return changed

def patch_ch09(obj):
    changed = False
    files = obj.setdefault("files", {})
    figures = files.get("figures", [])
    wildcard = "zz-figures/chapter09/p95_methods/*.png"
    if wildcard in figures:
        figures.remove(wildcard)
        print(f"    [ch09:figures] suppression de l’entrée wildcard {wildcard!r}")
        changed = True
    files["figures"] = figures
    obj["files"] = files
    return changed

for n in range(1, 11):
    path = root / f"chapter_manifest_{n:02d}.json"
    if not path.exists():
        continue

    raw = path.read_text(encoding="utf-8")
    obj = json.loads(raw)

    print("=" * 70)
    print(f"Manifest : {path}")
    chapter = obj.get("chapter")
    title = obj.get("title")
    print(f"  Chapter {chapter} – {title}")

    changed = False
    if chapter == 2:
        changed = patch_ch02(obj)
    elif chapter == 3:
        changed = patch_ch03(obj)
    elif chapter == 4:
        changed = patch_ch04(obj)
    elif chapter == 7:
        changed = patch_ch07(obj)
    elif chapter == 9:
        changed = patch_ch09(obj)

    if changed:
        backup(path, raw)
        path.write_text(json.dumps(obj, indent=2, sort_keys=False) + "\n", encoding="utf-8")
        print(f"  [WRITE] {path} mis à jour")
    else:
        print("  [SKIP] aucune modification nécessaire")

PYEOF

echo
echo "Terminé (patch_01_fix_chapter_manifests)."
read -rp "Appuie sur Entrée pour revenir au shell..." _
