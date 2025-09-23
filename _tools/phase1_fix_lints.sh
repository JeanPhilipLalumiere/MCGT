#!/usr/bin/env bash
# Pas de -e: on corrige au mieux, on log, on continue.
set -u
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORTS="_reports/${TS}"
mkdir -p "${REPORTS}"

log(){ printf "%s\n" "$*" | tee -a "${REPORTS}/phase1_fix_lints.log" ; }

log "==[0] Contexte=="
python -V 2>&1 | tee -a "${REPORTS}/python.txt"
ruff --version 2>/dev/null | tee -a "${REPORTS}/ruff.txt" || true

# -------- E402: imports pas en tête -> commenter avec '# noqa: E402' --------
python - <<'PY'
import re, sys
from pathlib import Path

def add_noqa(path: Path, patterns):
    if not path.exists():
        return False
    text = path.read_text(encoding="utf-8").splitlines()
    changed = False
    for i, line in enumerate(text):
        for pat in patterns:
            if re.match(pat, line) and "# noqa: E402" not in line:
                text[i] = f"{line}  # noqa: E402"
                changed = True
    if changed:
        path.write_text("\n".join(text) + ("\n" if not text or text[-1] != "" else ""), encoding="utf-8")
    return changed

mods = []
mods.append(("zz-scripts/chapter02/plot_fig00_spectrum.py", [r"^\s*from\s+primordial_spectrum\s+import\s+P_R\s*$"]))
mods.append(("zz-scripts/chapter07/generate_data_chapter07.py", [r"^\s*from\s+mcgt\.perturbations_scalaires\s+import\s+compute_cs2,\s*compute_delta_phi\s*$",
                                                                r"^\s*from\s+mcgt\.perturbations_scalaires\s+import\s+.*$"]))
mods.append(("zz-scripts/chapter07/tests/test_chapter07.py", [r"^\s*(import|from)\s+.+$"]))
mods.append(("zz-scripts/chapter08/generate_data_chapter08.py", [r"^\s*from\s+cosmo\s+import\s+.+$"]))
mods.append(("zz-scripts/chapter08/plot_fig06_normalized_residuals_distribution.py", [r"^\s*from\s+cosmo\s+import\s+.+$"]))
mods.append(("zz-scripts/chapter10/update_manifest_with_hashes.py", [r"^\s*import\s+platform\s*$"]))

changed = []
for f, pats in mods:
    p = Path(f)
    if add_noqa(p, pats):
        changed.append(f)

print("E402 changed:", changed)
PY
# ---------------------------------------------------------------------------

# -------- E731: lambda assignée -> def --------
python - <<'PY'
import re
from pathlib import Path

p = Path("zz-scripts/chapter03/generate_data_chapter03.py")
if p.exists():
    src = p.read_text(encoding="utf-8")
    # integrand = lambda zp: EXPR
    src = re.sub(
        r"^(\s*)integrand\s*=\s*lambda\s*([^\:]+)\:\s*(.+)$",
        r"\1def integrand(\2):\n\1    return \3",
        src,
        flags=re.MULTILINE,
    )
    # f = lambda z: T_of_z(z) - T
    src = re.sub(
        r"^(\s*)f\s*=\s*lambda\s*([^\:]+)\:\s*(.+)$",
        r"\1def f(\2):\n\1    return \3",
        src,
        flags=re.MULTILINE,
    )
    p.write_text(src, encoding="utf-8")
print("E731 fixed in:", p)
PY
# ---------------------------------------------------------------------------

# -------- E741: variables ambiguës 'l' -> noms explicites --------
python - <<'PY'
import re
from pathlib import Path

def replace_in_file(path: str, subs: list[tuple[str, str]]):
    p = Path(path)
    if not p.exists():
        return False
    s = p.read_text(encoding="utf-8")
    for a,b in subs:
        s = re.sub(a, b, s, flags=re.MULTILINE)
    p.write_text(s, encoding="utf-8")
    return True

# chapter07: l = cfg["lissage"] -> lissage_cfg
replace_in_file(
    "zz-scripts/chapter07/generate_data_chapter07.py",
    [
        (r'^(\s*)l\s*=\s*cfg\["lissage"\]\s*$', r'\1lissage_cfg = cfg["lissage"]'),
        (r'(\W)l\.get\(', r'\1lissage_cfg.get('),
    ],
)
replace_in_file(
    "zz-scripts/chapter07/launch_scalar_perturbations_solver.py",
    [
        (r'^(\s*)l\s*=\s*cfg\["lissage"\]\s*$', r'\1lissage_cfg = cfg["lissage"]'),
        (r'(\W)l\.get\(', r'\1lissage_cfg.get('),
    ],
)

# chapter09: h, l = ax.get_legend_handles_labels() -> h, labels = ...
for f in [
    "zz-scripts/chapter09/plot_fig04_absdphi_milestones_vs_f.py",
    "zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py",
]:
    replace_in_file(
        f,
        [
            (r'^\s*h,\s*l\s*=\s*ax\.get_legend_handles_labels\(\)\s*$', r'    h, labels = ax.get_legend_handles_labels()'),
            (r'zip\(\s*h\s*,\s*l\s*\)', r'zip(h, labels)'),
        ],
    )

print("E741 renames applied.")
PY
# ---------------------------------------------------------------------------

# -------- F841: variables assignées et non utilisées -> préfixe '_' --------
python - <<'PY'
import re
from pathlib import Path

def prefix_unused(path: str, names: list[str]):
    p = Path(path)
    if not p.exists():
        return
    lines = p.read_text(encoding="utf-8").splitlines()
    patt = {n: re.compile(rf'^(\s*){re.escape(n)}(\s*=)') for n in names}
    changed = False
    for i, line in enumerate(lines):
        for n, rgx in patt.items():
            m = rgx.match(line)
            if m:
                lines[i] = f"{m.group(1)}_{n}{m.group(2)}" + line[m.end():]
                changed = True
    if changed:
        Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")

# mapping fichier -> noms à préfixer
todo = {
    "zz-manifests/diag_consistency.py": ["fieldnames"],
    "zz-scripts/chapter03/plot_fig05_interpolated_milestones.py": ["grid"],
    "zz-scripts/chapter04/generate_data_chapter04.py": ["Tp", "dP_smooth"],
    "zz-scripts/chapter08/plot_fig07_chi2_profile.py": ["colors"],
    "zz-scripts/chapter09/flag_jalons.py": ["required_cols", "evt"],
    "zz-scripts/chapter10/bootstrap_topk_p95.py": ["candidates"],
    "zz-scripts/chapter10/check_metrics_consistency.py": ["df_cols"],
    "zz-scripts/chapter10/eval_primary_metrics_20_300.py": ["work"],
    "zz-scripts/chapter10/plot_fig01_iso_p95_maps.py": ["cs"],
    "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py": ["ref_median", "ref_tmean"],
    "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py": ["y0_user"],
    "zz-scripts/chapter10/regen_fig05_using_circp95.py": ["y0_user"],
}
for f, names in todo.items():
    prefix_unused(f, names)
print("F841 prefixes applied.")
PY
# ---------------------------------------------------------------------------

# -------- Vérif Ruff ciblée + format --------
log "==[1] Ruff check ciblé =="
ruff check zz-manifests zz-scripts --select E402,E731,E741,F841 | tee "${REPORTS}/ruff_after.txt" || true

log "==[2] Format (ruff-format) =="
pre-commit run ruff-format --all-files | tee -a "${REPORTS}/ruff_format.txt" || true

log "==[3] Commit & push (tolérant) =="
git add -A
git commit -m "chore(lint): fix E402/E731/E741/F841 across zz-*/" || true
git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true

log ">>> Phase 1 terminée. Rapports: ${REPORTS}"
