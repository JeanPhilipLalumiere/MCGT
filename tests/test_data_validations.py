import subprocess
import pathlib
import re


def test_data_validations_bad_eq_zero():
    root = pathlib.Path(__file__).resolve().parents[1]
    script = root / "zz-schemas" / "validate_all.sh"
    proc = subprocess.run(
        ["bash", str(script)], cwd=root, capture_output=True, text=True, check=False
    )
    out = proc.stdout + proc.stderr
    bad = [int(x) for x in re.findall(r"bad=([0-9]+)", out)]
    assert bad and all(
        b == 0 for b in bad
    ), f"Expected bad=0 everywhere.\n---OUTPUT---\n{out}"
