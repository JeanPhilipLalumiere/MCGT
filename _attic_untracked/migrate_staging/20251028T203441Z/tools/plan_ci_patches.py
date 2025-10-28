#!/usr/bin/env python3
import re
from pathlib import Path

WF_DIR = Path(".github/workflows")
OUT_DIR = Path(".ci-out")
OUT_DIR.mkdir(exist_ok=True, parents=True)
PLAN = OUT_DIR / "ci_patch_plan.txt"
MISSING = OUT_DIR / "ci_missing_setup_python.txt"

workflows = sorted([p for p in WF_DIR.glob("*.y*ml") if p.is_file()])
timeout_hits = []
pyver_changes = []
no_setup = []

for wf in workflows:
    text = wf.read_text(encoding="utf-8", errors="ignore")
    # Heuristique: détecter des jobs (lignes 'runs-on' sous une indention)
    # Timeout: vérifier présence de 'timeout-minutes:' dans le fichier
    has_timeout = re.search(r"^\s*timeout-minutes\s*:", text, re.M)
    # Setup-python step?
    has_setup = re.search(r"^\s*uses\s*:\s*actions/setup-python@v\d+\s*$", text, re.M)
    if not has_setup:
        no_setup.append(wf)

    # Forcer python-version: '3.12' dans 'with:' d'un setup-python
    patched = False
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if re.search(r"^\s*uses\s*:\s*actions/setup-python@v\d+\s*$", line):
            # search the following 'with:' block (simple heuristic)
            j = i + 1
            while j < len(lines) and (
                lines[j].strip() == "" or lines[j].startswith((" ", "\t"))
            ):
                if re.search(r"^\s*with\s*:\s*$", lines[j]):
                    # within with:, ensure python-version: '3.12'
                    k = j + 1
                    found = False
                    while k < len(lines) and (
                        lines[k].startswith((" ", "\t"))
                        and not re.match(r"^\s*\S", lines[k].lstrip())
                    ):
                        if re.search(r"^\s*python-version\s*:", lines[k]):
                            found = True
                            if not re.search(r"'?3\.12'?", lines[k]):
                                pyver_changes.append((wf, k + 1, lines[k].strip()))
                            break
                        k += 1
                    if not found:
                        # no python-version line at all
                        pyver_changes.append(
                            (wf, j + 1, "(insert python-version: '3.12')")
                        )
                    break
                j += 1

    if not has_timeout:
        timeout_hits.append(wf)

# Write plan
with PLAN.open("w", encoding="utf-8") as f:
    f.write("# Plan de patch CI (dry-run)\n\n")
    if timeout_hits:
        f.write(
            "== Ajouter `timeout-minutes: 15` à ces workflows (au niveau des jobs sans timeout) ==\n"
        )
        for p in timeout_hits:
            f.write(f"- {p}\n")
        f.write("\n")
    else:
        f.write(
            "== Tous les workflows contiennent déjà au moins un `timeout-minutes` ==\n\n"
        )

    if pyver_changes:
        f.write(
            "== Forcer/insérer `python-version: '3.12'` dans les steps setup-python suivants ==\n"
        )
        for wf, lineno, ctx in pyver_changes:
            f.write(f"- {wf}:{lineno}  -> {ctx}\n")
        f.write("\n")
    else:
        f.write("== Aucune modification python-version détectée ==\n\n")

with MISSING.open("w", encoding="utf-8") as f:
    if no_setup:
        f.write("# Workflows sans actions/setup-python\n")
        for p in no_setup:
            f.write(f"- {p}\n")
    else:
        f.write("# Tous les workflows utilisent actions/setup-python\n")

print(f"[ci-plan] écrit: {PLAN}")
print(f"[ci-plan] manques setup-python: {MISSING}")
