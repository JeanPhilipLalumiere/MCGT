# --- auto-inserted by migration helper ---
from pathlib import Path

import pytest

_ROOT = Path(__file__).resolve().parents[2]
_CANDIDATES = [
    _ROOT / "zz-data/chapter07/07_phase_run.csv",
]
_DATA_07 = next((c for c in _CANDIDATES if c.exists()), None)
if _DATA_07 is None:
    pytest.skip(
        "missing 07_phase_run.csv (chapter07); skipping data-dependent tests",
        allow_module_level=True,
    )
# ------------------------------------------------

# zz-scripts/chapter07/tests/test_chapter07.py

from pathlib import Path

import pandas as pd
import pytest

RTOL = 1e-3

# Project root is three levels up from this test file:
ROOT = Path(__file__).resolve().parents[3]

DATA_DIR = ROOT / "zz-data" / "chapter07"
RAW_CSV = DATA_DIR / "07_phase_run.csv"
REF_CSV = (
    Path(__file__).parent / "ref_phase_run.csv"
)  # mettre votre CSV de référence ici


def test_raw_csv_exists():
    """Le fichier raw 07_phase_run.csv doit exister."""
    assert RAW_CSV.exists(), f"Fichier introuvable : {RAW_CSV}"


def test_reference_csv_exists():
    """Le fichier de référence doit exister."""
    assert REF_CSV.exists(), f"Fichier de référence introuvable : {REF_CSV}"


def test_shape_matches():
    """Le raw et la référence doivent avoir la même forme."""
    df = pd.read_csv(RAW_CSV)
    df_ref = pd.read_csv(REF_CSV)
    assert (
        df.shape == df_ref.shape
    ), f"Formes différentes : {df.shape} vs {df_ref.shape}"


def test_no_nan_inf():
    """Aucune valeur NaN ou Inf dans les deux fichiers."""
    df = pd.read_csv(RAW_CSV)
    df_ref = pd.read_csv(REF_CSV)
    assert df.replace([float("inf"), -float("inf")], pd.NA).notna().all().all()
    assert df_ref.replace([float("inf"), -float("inf")], pd.NA).notna().all().all()


def test_columns_present():
    """Les colonnes attendues doivent être présentes."""
    expected = {"k", "a", "cs2_raw", "delta_phi_raw"}
    df = pd.read_csv(RAW_CSV)
    df_ref = pd.read_csv(REF_CSV)
    missing_raw = expected - set(df.columns)
    missing_ref = expected - set(df_ref.columns)
    assert not missing_raw, f"Colonnes manquantes dans raw : {missing_raw}"
    assert not missing_ref, f"Colonnes manquantes dans ref : {missing_ref}"


def test_values_within_tolerance():
    """Les valeurs numériques correspondent à la référence à rtol=1e-3."""
    df = pd.read_csv(RAW_CSV)
    df_ref = pd.read_csv(REF_CSV)

    for col in ["k", "a", "cs2_raw", "delta_phi_raw"]:
        raw_vals = df[col].to_numpy()
        ref_vals = df_ref[col].to_numpy()
        assert raw_vals == pytest.approx(
            ref_vals, rel=RTOL
        ), f"Différence trop grande dans la colonne '{col}'"
