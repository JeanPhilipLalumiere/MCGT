import csv
import os

CSV = "assets/zz-data/chapter10/10_mc_results.csv"


def test_ch10_csv_exists_and_has_headers():
    assert os.path.exists(CSV), f"{CSV} manquant"
    with open(CSV, newline="", encoding="utf-8") as f:
        r = csv.reader(f)
        header = next(r, None)
        assert header, "header vide"
        expected = {
            "sample_id",
            "q",
            "m1",
            "m2",
            "fpeak_hz",
            "phi_at_fpeak_rad",
            "p95_rad",
        }
        assert expected.issubset(set(header)), (
            f"headers attendus manquants: {expected - set(header)}"
        )
        # au moins 5 lignes pour valider le run
        rows = sum(1 for _ in r)
        assert rows >= 5, f"trop peu de lignes: {rows}"
