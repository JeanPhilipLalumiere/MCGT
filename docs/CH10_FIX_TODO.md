# TODO: Corriger IndentationError ch10

## Contexte lignes 346–386
```
    cfg_base: Path, cfg_out: Path, boite: dict, log: logging.Logger
):
    base = load_json(cfg_base)
    # Adapter les bornes uniquement sur les 4 paramètres libres
    for key in ["m1", "m2", "q0star", "alpha"]:
        if key in base.get("priors", {}):
            base["priors"][key]["min"] = float(boite[key]["min"])
            base["priors"][key]["max"] = float(boite[key]["max"])
    save_json(base, cfg_out)
    log.info("   ↪ Config de raffinement écrite : %s", bref(cfg_out))


def _assurer_ids_uniques(samples_path: Path, id_offset: int, log: logging.Logger):
    """
    Re-numérotation simple : id := id + id_offset (garantit unicité lors de fusions).
    """
    import pandas as pd

from tools import common_io as ci

    df = pd.read_csv(samples_path)
df = ci.ensure_fig02_cols(df)

    if "id" not in df.columns:
        raise RuntimeError("Le fichier d'échantillons n'a pas de colonne 'id'.")
    df["id"] = df["id"].astype(int) + int(id_offset)
    tmp = samples_path.with_suffix(".tmp.csv")
    df.to_csv(tmp, index=False, float_format="%.6f")
    os.replace(tmp, samples_path)
    log.info("   ↪ IDs décalés de +%d dans %s", id_offset, bref(samples_path))


def etape_6_raffinement(
    args,
    log: logging.Logger,
    best_json_final: Path,
    samples_global: Path,
    results_global: Path,
):
    if not args.refine:
        log.info("6) Raffinement global — SKIP (désactivé)")
```

## Traceback avant fix
```
  File "/home/jplal/MCGT/scripts/chapter10/generate_data_chapter10.py", line 366
    df = pd.read_csv(samples_path)
IndentationError: unexpected indent
```

## Traceback après fix
```
  File "/home/jplal/MCGT/scripts/chapter10/generate_data_chapter10.py.tmpfix", line 368
    if "id" not in df.columns:
IndentationError: unexpected indent
```
# CH10_FIX_TODO
- Le correctif heuristique n'a pas suffi (RC=1).
- Voir traces: _snapshots/ch10_fix/run_after.stderr
- Pistes: vérifier le bloc englobant (if/for/def) et l'alignement de toutes les lignes du bloc.
## TODO (proper upstream fix for ch10)
- Restore the full original logic in `generate_data_chapter10.py` (now saved as `*.broken.YYYYMMDDTHHMMSS`).
- Re-indent/clean the function surrounding former line ~366; verify with py_compile and run.
- Replace the minimal stub with the fixed implementation, keep the same CLI.
