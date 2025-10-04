#!/usr/bin/env python3
import pathlib
import re

OUT_BAD = pathlib.Path(".ci-out/figures_bad_names.tsv")
OUT_ALL = pathlib.Path(".ci-out/figures_all.tsv")
OUT_BAD.parent.mkdir(parents=True, exist_ok=True)

rx_ok = re.compile(r"^zz-figures/chapter[0-9]{2}/[0-9]{2}_fig_[a-z0-9_]+\.(png|pdf)$")

all_rows = []
bad_rows = []

for p in sorted(pathlib.Path("zz-figures").rglob("*")):
    if not p.is_file():
        continue
    if p.suffix.lower() not in [".png", ".pdf"]:
        continue
    rel = p.as_posix()
    ok = bool(rx_ok.match(rel))
    size = p.stat().st_size
    all_rows.append((rel, size, "ok" if ok else "bad"))
    if not ok:
        bad_rows.append((rel, size))

with OUT_ALL.open("w", encoding="utf-8") as f:
    f.write("path\tsize_bytes\tstatus\n")
    for r in all_rows:
        f.write(f"{r[0]}\t{r[1]}\t{r[2]}\n")

with OUT_BAD.open("w", encoding="utf-8") as f:
    f.write("path\tsize_bytes\n")
    for r in bad_rows:
        f.write(f"{r[0]}\t{r[1]}\n")

print(f"[figures] {len(all_rows)} total, {len(bad_rows)} bad → {OUT_BAD}, {OUT_ALL}")
