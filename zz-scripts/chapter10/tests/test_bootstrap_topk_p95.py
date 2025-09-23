import tempfile
from pathlib import Path
import importlib.util
import sys
import types

# Stubs minimalistes pour éviter les deps lourdes lors de l'import du module testé
if "numpy" not in sys.modules:
    sys.modules["numpy"] = types.ModuleType("numpy")
if "pandas" not in sys.modules:
    pd_stub = types.ModuleType("pandas")
    pd_stub.DataFrame = type("DataFrame", (), {})
    sys.modules["pandas"] = pd_stub

# Charger le module directement depuis son chemin (car "zz-scripts" a un tiret)
ROOT = Path(__file__).resolve().parents[3]
MOD_PATH = ROOT / "zz-scripts" / "chapter10" / "bootstrap_topk_p95.py"

spec = importlib.util.spec_from_file_location("bootstrap_topk_p95", MOD_PATH)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)


def test_find_top_residuals_prefers_exact_residuals_csv():
    with tempfile.TemporaryDirectory() as d:
        resid_dir = Path(d)
        id_ = "ABC123"
        # deux candidats ; on doit préférer *_residuals.csv à *_topresiduals.csv
        (resid_dir / f"{id_}_topresiduals.csv").write_text("a,b\n", encoding="utf-8")
        p_main = resid_dir / f"{id_}_residuals.csv"
        p_main.write_text("a,b\n", encoding="utf-8")

        mod.resid_dir, mod.id_ = resid_dir, id_
        out = mod.find_top_residuals()
        assert out == p_main


def test_find_top_residuals_glob_fallback():
    with tempfile.TemporaryDirectory() as d:
        resid_dir = Path(d)
        id_ = "XYZ"
        any_path = resid_dir / f"foo_{id_}_bar.csv"
        any_path.write_text("x,y\n", encoding="utf-8")

        mod.resid_dir, mod.id_ = resid_dir, id_
        out = mod.find_top_residuals()
        assert out == any_path
