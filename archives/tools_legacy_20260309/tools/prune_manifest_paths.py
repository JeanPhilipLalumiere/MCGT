# tools/prune_manifest_paths.py
#!/usr/bin/env python3
"""
Prune des entrées indésirables dans un manifest JSON (clé "files":[{"path":...}]).
- Lit le manifest d'entrée
- Supprime les chemins qui matchent DROP_REGEX (env) ou les motifs passés en --drop
- Écrit un JSON minimal {"files":[{"path":"..."}]} trié et dédoublonné
Exit codes:
  0 = OK, pas de changement
  1 = manifest introuvable ou JSON invalide
  2 = erreur d'écriture
  3 = autre erreur
"""

from __future__ import annotations
import os
import sys
import re
import json
import argparse
import pathlib
import hashlib


def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def norm_manifest(obj: dict) -> dict:
    files = obj.get("files", [])
    norm = []
    for it in files:
        if not isinstance(it, dict):
            continue
        p = str(it.get("path", "")).strip()
        if p:
            norm.append({"path": p})
    # dédoublonnage + tri
    seen = set()
    uniq = []
    for it in norm:
        if it["path"] not in seen:
            seen.add(it["path"])
            uniq.append(it)
    uniq.sort(key=lambda x: x["path"])
    return {"files": uniq}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", required=True, help="manifest source (JSON)")
    ap.add_argument(
        "--out",
        dest="out",
        required=True,
        help="fichier de sortie (peut être identique à --in)",
    )
    ap.add_argument(
        "--drop",
        action="append",
        default=[],
        help="regex à exclure (ajoutée à DROP_REGEX)",
    )
    args = ap.parse_args()

    drop_regex_env = os.environ.get("DROP_REGEX", "")
    drops = [r for r in (drop_regex_env.split("||") if drop_regex_env else []) if r]
    drops.extend(args.drop or [])
    drop_re = re.compile("|".join(drops)) if drops else None

    inp = pathlib.Path(args.inp)
    out = pathlib.Path(args.out)

    if not inp.exists():
        print(f"[ERR] manifest introuvable: {inp}", file=sys.stderr)
        return 1

    try:
        raw = inp.read_bytes()
        data = json.loads(raw)
    except Exception as e:
        print(f"[ERR] JSON invalide pour {inp}: {e}", file=sys.stderr)
        return 1

    base = norm_manifest(data)
    before = base["files"]

    if drop_re:
        kept = [it for it in before if not drop_re.search(it["path"])]
    else:
        kept = before

    out_obj = {"files": kept}
    out_bytes = (json.dumps(out_obj, ensure_ascii=False, indent=2) + "\n").encode(
        "utf-8"
    )

    changed = sha256_bytes(out_bytes) != sha256_bytes(
        (json.dumps(base, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    )
    try:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(out_bytes)
    except Exception as e:
        print(f"[ERR] écriture échouée: {out}: {e}", file=sys.stderr)
        return 2

    print(
        f"[OK] {inp} → {out} | avant={len(before)} après={len(kept)} drop={len(before) - len(kept)}"
    )
    return 0 if not changed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(3)
