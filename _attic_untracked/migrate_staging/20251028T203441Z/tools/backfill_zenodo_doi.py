#!/usr/bin/env python3
import re
import sys
import os
import time
import shutil

README = "README.md"
CFF = "CITATION.cff"


def backup(p: str) -> None:
    if os.path.exists(p):
        b = f"{p}.bak.{int(time.time())}"
        try:
            shutil.copy2(p, b)
        except Exception:
            pass
        print(f"[backup] {p} -> {b}")


def upsert_readme(doi: str) -> None:
    if not os.path.exists(README):
        print(f"[warn] {README} introuvable — skip")
        return
    backup(README)
    txt = open(README, "r", encoding="utf-8").read()

    badge = f"[![DOI](https://zenodo.org/badge/DOI/{doi}.svg)](https://doi.org/{doi})"
    block_start = "<!-- ZENODO_BADGE_START -->"
    block_end = "<!-- ZENODO_BADGE_END -->"
    block = (
        block_start
        + "\n"
        + badge
        + "\n\n"
        + "### Citation\n"
        + f"Si vous utilisez MCGT, merci de citer la version DOI : **{doi}**.\n"
        + "Voir aussi `CITATION.cff`.\n"
        + block_end
        + "\n"
    )

    if block_start in txt and block_end in txt:
        txt = re.sub(
            rf"{re.escape(block_start)}.*?{re.escape(block_end)}",
            block,
            txt,
            flags=re.DOTALL,
        )
        print("[readme] bloc Zenodo mis à jour")
    else:
        if not txt.endswith("\n"):
            txt += "\n"
        txt += "\n---\n" + block
        print("[readme] bloc Zenodo ajouté en fin de README")

    open(README, "w", encoding="utf-8").write(txt)


def upsert_cff(doi: str) -> None:
    if not os.path.exists(CFF):
        print(f"[warn] {CFF} introuvable — skip")
        return
    backup(CFF)
    txt = open(CFF, "r", encoding="utf-8").read()

    if re.search(r"^doi:\s*", txt, flags=re.MULTILINE):
        txt = re.sub(r"^doi:\s*.*$", f"doi: {doi}", txt, flags=re.MULTILINE)
        print("[cff] doi mis à jour")
    else:
        if re.search(r"^title:\s*.*$", txt, flags=re.MULTILINE):
            txt = re.sub(
                r"^(title:.*\n)",
                r"\1doi: " + doi + "\n",
                txt,
                count=1,
                flags=re.MULTILINE,
            )
            print("[cff] doi inséré après title")
        else:
            txt = "doi: " + doi + "\n" + txt
            print("[cff] doi inséré en tête")

    open(CFF, "w", encoding="utf-8").write(txt)


def main() -> None:
    if len(sys.argv) < 2:
        print(
            "usage: backfill_zenodo_doi.py DOI\nex:   backfill_zenodo_doi.py 10.5281/zenodo.1234567"
        )
        sys.exit(2)
    doi = sys.argv[1].strip()
    upsert_readme(doi)
    upsert_cff(doi)
    print("[ok] backfill DOI terminé.")


if __name__ == "__main__":
    main()
