from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def tracer_fig03_yp_modele_contre_obs(
    save_path="zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png",
):
    # Racine du projet
    ROOT = Path.cwd()
    DATA_DIR = ROOT / "zz-data" / "chapter05"
    FIG_DIR = ROOT / "zz-figures" / "chapter05"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # Lecture des données (ignorer les commentaires et espaces)
    jalons = pd.read_csv(
        DATA_DIR / "05_bbn_milestones.csv", comment="#", skipinitialspace=True
    )
    data = pd.read_csv(DATA_DIR / "05_bbn_data.csv")

    # Conversion numérique
    jalons["Yp_obs"] = pd.to_numeric(jalons["Yp_obs"], errors="coerce")
    jalons["sigma_Yp"] = pd.to_numeric(jalons["sigma_Yp"], errors="coerce")
    jalons["T_Gyr"] = pd.to_numeric(jalons["T_Gyr"], errors="coerce")

    # Filtrer jalons valides
    clean = jalons.dropna(subset=["Yp_obs", "sigma_Yp", "T_Gyr"])

    # Interpolation simple de Yp_calc aux temps des jalons
    T_j = clean["T_Gyr"].values
    Yp_obs = clean["Yp_obs"].values
    sigma_Yp = clean["sigma_Yp"].values
    Yp_calc = np.interp(T_j, data["T_Gyr"].values, data["Yp_calc"].values)

    # Création de la figure
    fig, ax = plt.subplots(figsize=(8, 6))
    # Tracer les jalons avec barres d'erreur horizontales
    ax.errorbar(
        Yp_obs,
        Yp_calc,
        xerr=sigma_Yp,
        fmt="o",
        capsize=3,
        label="Jalons Yp")

    # Mettre en échelle log–log
    ax.set_xscale("log")
    ax.set_yscale("log")

    # Étendre la droite y = x sur toute la plage visible
    ax.set_aspect("equal", "box")
    # obtenir limites communes
    all_vals = np.concatenate([Yp_obs, Yp_calc])
    val_min, val_max = all_vals.min(), all_vals.max()
    # ajouter un petit margin
    margin = 0.1 * (val_max - val_min)
    lims = [val_min - margin, val_max + margin]
    ax.plot(lims, lims, "--", color="gray", label=r"$y=x$")
    ax.set_xlim(lims)
    ax.set_ylim(lims)

    # Labels et titre
    ax.set_xlabel(r"$Y_{p,\rm obs}$")
    ax.set_ylabel(r"$Y_{p,\rm calc}$")
    ax.set_title("Comparaison Yp modèle vs observations")
    ax.legend()

    # Sauvegarde
    plt.tight_layout()
    plt.savefig(save_path, dpi=300)
    plt.close()


if __name__ == "__main__":
    tracer_fig03_yp_modele_contre_obs()

# [MCGT POSTPARSE EPILOGUE v1]
try:
    # On n agit que si un objet args existe au global
    if "args" in globals():
        import os
        import atexit
        # 1) Fallback via MCGT_OUTDIR si outdir est vide/None
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out
        # 2) Création sûre du répertoire s il est défini
        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass
        # 3) rcParams savefig si des attributs existent
        try:
            import matplotlib
            _rc = {}
            if hasattr(args, "dpi") and args.dpi:
                _rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                _rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                _rc["savefig.transparent"] = bool(args.transparent)
            if _rc:
                matplotlib.rcParams.update(_rc)
        except Exception:
            pass
        # 4) Copier automatiquement le dernier PNG vers outdir à la fin

        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob
                import os
                import shutil
                _ch = os.path.basename(os.path.dirname(__file__))
                _repo = os.path.abspath(
                    os.path.join(
                        os.path.dirname(__file__),
                        "..",
                        ".."))
                _default_dir = os.path.join(_repo, "zz-figures", _ch)
                pngs = sorted(
                    glob.glob(os.path.join(_default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for _p in pngs:
                    if os.path.exists(_p):
                        _dst = os.path.join(args.outdir, os.path.basename(_p))
                        if not os.path.exists(_dst):
                            shutil.copy2(_p, _dst)
                        break
            except Exception:
                pass
        atexit.register(_smoke_copy_latest)
except Exception:
    # épilogue best-effort — ne doit jamais casser le script principal
    pass
